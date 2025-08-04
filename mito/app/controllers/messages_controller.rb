class MessagesController < ApplicationController
  before_action :set_chat

  def create
    @message = @chat.messages.build(message_params.merge(role: 'user'))
    
    if @message.save
      # Update chat title if it's the first message
      update_chat_title if @chat.messages.count == 1
      
      # Get assistant response from FastAPI
      assistant_response = get_assistant_response(@message.content)
      
      if assistant_response == :comparison
        # For admin users with comparison data - create separate messages for each variant
        comparison_group_id = SecureRandom.uuid
        @comparison_messages = []
        
        @comparison_data['responses'].each do |variant_response|
          message = @chat.messages.create!(
            content: variant_response['response'],
            role: 'assistant',
            variant: variant_response['variant_name'],
            comparison_group_id: comparison_group_id,
            processing_time: variant_response['processing_time']
          )
          
          # Persist sources for each variant
          persist_sources_for_variant(message, variant_response['sources']) if variant_response['sources'].present?
          @comparison_messages << message
        end
      elsif assistant_response
        # For regular users - create single assistant message
        @assistant_message = @chat.messages.create!(
          content: assistant_response,
          role: 'assistant'
        )
        
        # Persist sources for the assistant message
        persist_sources_for_message(@assistant_message) if @sources.present?
      end

      respond_to do |format|
        format.json { render_json_response }
        format.turbo_stream
        format.html { redirect_to chat_path(@chat) }
      end
    else
      redirect_to chat_path(@chat), alert: 'Chyba pri posielaní správy.'
    end
  end

  private

  def set_chat
    @chat = current_user.chats.find(params[:chat_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: 'Chat nenájdený.'
  end

  def message_params
    params.require(:message).permit(:content)
  end

  def update_chat_title
    # Generate title from first message (first 50 characters)
    title = @message.content.truncate(50)
    @chat.update!(title: title)
  end

  def get_assistant_response(user_message)
    begin
      if current_user.admin?
        # Admin users get comparison responses
        response = HTTP.timeout(30).post(
          'http://localhost:8000/api/chat/compare',
          json: {
            message: user_message,
            session_id: @chat.id
          }
        )

        if response.status.success?
          @comparison_data = JSON.parse(response.body)
          return :comparison # Signal that this is comparison data
        else
          Rails.logger.error "FastAPI Compare Error: #{response.status} - #{response.body}"
          return 'Prepáčte, nastala chyba pri porovnaní odpovedí. Skúste to znovu.'
        end
      else
        # Regular users get single response
        response = HTTP.timeout(30).post(
          'http://localhost:8000/api/chat',
          json: {
            message: user_message,
            session_id: @chat.id
          }
        )

        if response.status.success?
          response_data = JSON.parse(response.body)
          @sources = response_data['sources'] || []
          response_data['response']
        else
          @sources = []
          'Prepáčte, nastala chyba pri spracovaní vašej otázky. Skúste to znovu.'
        end
      end
    rescue => e
      Rails.logger.error "FastAPI Error: #{e.message}"
      @sources = []
      'Prepáčte, služba momentálne nie je dostupná. Skúste to neskôr.'
    end
  end

  def render_json_response
    response_data = {
      success: true,
      user_message: {
        id: @message.id,
        content: @message.content,
        role: @message.role,
        created_at: @message.created_at
      }
    }

    if @comparison_data
      response_data[:comparison_data] = @comparison_data
      # Also include the persisted comparison messages for future reference
      if @comparison_messages
        response_data[:comparison_messages] = @comparison_messages.map do |msg|
          {
            id: msg.id,
            content: msg.content,
            role: msg.role,
            variant: msg.variant,
            comparison_group_id: msg.comparison_group_id,
            processing_time: msg.processing_time,
            created_at: msg.created_at,
            sources: msg.sources.map do |source|
              message_source = msg.message_sources.find { |ms| ms.source_id == source.id }
              {
                id: source.id,
                title: source.title,
                url: source.url,
                excerpt: source.excerpt,
                relevance_score: message_source&.relevance_score || 0.0
              }
            end
          }
        end
      end
    elsif @assistant_message
      response_data[:assistant_message] = {
        id: @assistant_message.id,
        content: @assistant_message.content,
        role: @assistant_message.role,
        created_at: @assistant_message.created_at,
        sources: @assistant_message.sources.includes(:message_sources).map do |source|
          message_source = @assistant_message.message_sources.find { |ms| ms.source_id == source.id }
          {
            id: source.id,
            title: source.title,
            url: source.url,
            excerpt: source.excerpt,
            relevance_score: message_source&.relevance_score || 0.0
          }
        end
      }
    end

    # Add chat title if this is the first message
    if @chat.messages.count == 1
      response_data[:chat_title] = @chat.title
    end

    render json: response_data
  end
  
  def persist_sources_for_message(message)
    return unless @sources.is_a?(Array)
    
    @sources.each do |source_data|
      next unless source_data.is_a?(Hash) && source_data['url'].present?
      
      # Find or create source by URL to avoid duplicates
      source = Source.find_or_create_by(url: source_data['url']) do |s|
        s.title = source_data['title'] || 'Untitled'
        s.excerpt = source_data['excerpt']
        s.chunk_text = source_data['chunk_text']
        s.chunk_size = source_data['chunk_size']
        s.document_id = source_data['document_id']
        s.metadata = source_data['metadata']
      end
      
      # Create the association with relevance score
      message.message_sources.create!(
        source: source,
        relevance_score: source_data['relevance_score'] || 0.0
      )
    rescue => e
      Rails.logger.error "Error persisting source: #{e.message}"
      # Continue processing other sources even if one fails
    end
  end
  
  def persist_sources_for_variant(message, sources_array)
    return unless sources_array.is_a?(Array)
    
    sources_array.each do |source_data|
      next unless source_data.is_a?(Hash) && source_data['url'].present?
      
      # Find or create source by URL to avoid duplicates
      source = Source.find_or_create_by(url: source_data['url']) do |s|
        s.title = source_data['title'] || 'Untitled'
        s.excerpt = source_data['excerpt']
        s.chunk_text = source_data['chunk_text']
        s.chunk_size = source_data['chunk_size']
        s.document_id = source_data['document_id']
        s.metadata = source_data['metadata']
      end
      
      # Create the association with relevance score
      message.message_sources.create!(
        source: source,
        relevance_score: source_data['relevance_score'] || 0.0
      )
    rescue => e
      Rails.logger.error "Error persisting variant source: #{e.message}"
      # Continue processing other sources even if one fails
    end
  end
end
