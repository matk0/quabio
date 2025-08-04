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
          # Build message attributes with cost data
          message_attributes = {
            content: variant_response['response'],
            role: 'assistant',
            variant: variant_response['variant_name'],
            comparison_group_id: comparison_group_id,
            processing_time: variant_response['processing_time']
          }
          
          # Add cost and token usage data if available
          if variant_response['usage'].present?
            usage_data = variant_response['usage']
            # Calculate cost using Rails ModelPricing
            pricing = ModelPricing.current_pricing_for(usage_data['model'])
            cost_usd = pricing&.calculate_cost(usage_data['prompt_tokens'], usage_data['completion_tokens'])
            
            message_attributes[:total_cost_usd] = cost_usd
            message_attributes[:token_usage] = {
              'model' => usage_data['model'],
              'prompt_tokens' => usage_data['prompt_tokens'],
              'completion_tokens' => usage_data['completion_tokens'],
              'total_tokens' => usage_data['total_tokens']
            }
          end
          
          message = @chat.messages.create!(message_attributes)
          
          # Persist sources and usage data for each variant
          persist_sources_for_variant(message, variant_response['sources']) if variant_response['sources'].present?
          persist_usage_data(message, variant_response['usage']) if variant_response['usage'].present?
          @comparison_messages << message
        end
      elsif assistant_response
        # For regular users - create single assistant message with cost data
        message_attributes = {
          content: assistant_response,
          role: 'assistant'
        }
        
        # Add cost and token usage data if available
        if @usage_data.present?
          # Calculate cost using Rails ModelPricing
          pricing = ModelPricing.current_pricing_for(@usage_data['model'])
          cost_usd = pricing&.calculate_cost(@usage_data['prompt_tokens'], @usage_data['completion_tokens'])
          
          message_attributes[:total_cost_usd] = cost_usd
          message_attributes[:token_usage] = {
            'model' => @usage_data['model'],
            'prompt_tokens' => @usage_data['prompt_tokens'],
            'completion_tokens' => @usage_data['completion_tokens'],
            'total_tokens' => @usage_data['total_tokens']
          }
        end
        
        @assistant_message = @chat.messages.create!(message_attributes)
        
        # Persist sources and usage data for the assistant message
        persist_sources_for_message(@assistant_message) if @sources.present?
        persist_usage_data(@assistant_message, @usage_data) if @usage_data.present?
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
        # Admin users get comparison responses (parallel processing should be faster)
        response = HTTP.timeout(40).post(
          "#{Rails.configuration.fastapi_url}/api/chat/compare",
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
          "#{Rails.configuration.fastapi_url}/api/chat",
          json: {
            message: user_message,
            session_id: @chat.id
          }
        )

        if response.status.success?
          response_data = JSON.parse(response.body)
          @sources = response_data['sources'] || []
          @usage_data = response_data['usage']
          response_data['response']
        else
          Rails.logger.error "FastAPI Single Error: #{response.status} - #{response.body}"
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
    
    # Deduplicate sources by URL before processing
    unique_sources = @sources.uniq { |source| source['url'] }
    
    unique_sources.each do |source_data|
      next unless source_data.is_a?(Hash) && source_data['url'].present?
      
      # Find or create source by URL to avoid duplicates
      source = Source.find_or_create_by(url: source_data['url']) do |s|
        s.title = source_data['title'] || 'Untitled'
        s.excerpt = source_data['excerpt']
        # Remove deprecated fields - these are now in chunks
        # s.chunk_text = source_data['chunk_text']
        # s.chunk_size = source_data['chunk_size']
        # s.document_id = source_data['document_id']
        # s.metadata = source_data['metadata']
      end
      
      # Create the association with relevance score (avoid duplicates)
      unless message.message_sources.exists?(source: source)
        message.message_sources.create!(
          source: source,
          relevance_score: source_data['relevance_score'] || 0.0
        )
      end
      
      # Process chunks if they exist in the source data
      if source_data['chunks'].is_a?(Array)
        source_data['chunks'].each do |chunk_data|
          persist_chunk_for_message(message, source, chunk_data)
        end
      else
        # Fallback: create a single chunk from legacy source data
        chunk_data = {
          'id' => source_data['document_id'],
          'content' => source_data['chunk_text'],
          'excerpt' => source_data['excerpt'],
          'chunk_size' => source_data['chunk_size'],
          'chunk_type' => 'fixed', # Default for single messages
          'relevance_score' => source_data['relevance_score'],
          'document_id' => source_data['document_id'],
          'metadata' => source_data['metadata']
        }
        persist_chunk_for_message(message, source, chunk_data) if chunk_data['content'].present?
      end
    rescue => e
      Rails.logger.error "Error persisting source: #{e.message}"
      # Continue processing other sources even if one fails
    end
  end
  
  def persist_sources_for_variant(message, sources_array)
    return unless sources_array.is_a?(Array)
    
    # Deduplicate sources by URL before processing
    unique_sources = sources_array.uniq { |source| source['url'] }
    
    unique_sources.each do |source_data|
      next unless source_data.is_a?(Hash) && source_data['url'].present?
      
      # Find or create source by URL to avoid duplicates
      source = Source.find_or_create_by(url: source_data['url']) do |s|
        s.title = source_data['title'] || 'Untitled'
        s.excerpt = source_data['excerpt']
        # Remove deprecated fields - these are now in chunks
        # s.chunk_text = source_data['chunk_text']
        # s.chunk_size = source_data['chunk_size']
        # s.document_id = source_data['document_id']
        # s.metadata = source_data['metadata']
      end
      
      # Create the association with relevance score (avoid duplicates)
      unless message.message_sources.exists?(source: source)
        message.message_sources.create!(
          source: source,
          relevance_score: source_data['relevance_score'] || 0.0
        )
      end
      
      # Process chunks if they exist in the source data
      if source_data['chunks'].is_a?(Array)
        source_data['chunks'].each do |chunk_data|
          persist_chunk_for_message(message, source, chunk_data)
        end
      else
        # Fallback: create a single chunk from legacy source data
        chunk_data = {
          'id' => source_data['document_id'],
          'content' => source_data['chunk_text'],
          'excerpt' => source_data['excerpt'],
          'chunk_size' => source_data['chunk_size'],
          'chunk_type' => message.variant || 'fixed',
          'relevance_score' => source_data['relevance_score'],
          'document_id' => source_data['document_id'],
          'metadata' => source_data['metadata']
        }
        persist_chunk_for_message(message, source, chunk_data) if chunk_data['content'].present?
      end
    rescue => e
      Rails.logger.error "Error persisting variant source: #{e.message}"
      # Continue processing other sources even if one fails
    end
  end
  
  def persist_chunk_for_message(message, source, chunk_data)
    return unless chunk_data.is_a?(Hash) && chunk_data['content'].present?
    
    begin
      # Find or create chunk by content and source (to avoid true duplicates)
      chunk = source.chunks.find_or_create_by(
        content: chunk_data['content'],
        chunk_type: chunk_data['chunk_type'] || message.variant || 'fixed'
      ) do |c|
        c.excerpt = chunk_data['excerpt']
        c.chunk_size = chunk_data['chunk_size'] || chunk_data['content'].length
        c.document_id = chunk_data['document_id'] || chunk_data['id']
        c.metadata = chunk_data['metadata']
      end
      
      # Create message-chunk association with relevance score (avoid duplicates)
      unless message.message_chunks.exists?(chunk: chunk)
        message.message_chunks.create!(
          chunk: chunk,
          relevance_score: chunk_data['relevance_score'] || 0.0
        )
      end
    rescue => e
      Rails.logger.error "Error persisting chunk for message: #{e.message}"
    end
  end
  
  def persist_usage_data(message, usage_data)
    return unless usage_data.is_a?(Hash) && usage_data['total_tokens'].to_i > 0
    
    begin
      # Calculate cost using Rails ModelPricing
      pricing = ModelPricing.current_pricing_for(usage_data['model'])
      cost_usd = pricing&.calculate_cost(usage_data['prompt_tokens'], usage_data['completion_tokens']) || 0.0
      
      # Create API usage record for detailed tracking
      message.api_usages.create!(
        model: usage_data['model'] || 'unknown',
        prompt_tokens: usage_data['prompt_tokens'] || 0,
        completion_tokens: usage_data['completion_tokens'] || 0,
        total_tokens: usage_data['total_tokens'] || 0,
        cost_usd: cost_usd,
        request_timestamp: Time.current,
        response_time_ms: usage_data['response_time_ms']
      )
    rescue => e
      Rails.logger.error "Error persisting usage data: #{e.message}"
    end
  end
end
