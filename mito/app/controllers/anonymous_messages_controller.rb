class AnonymousMessagesController < ApplicationController
  protect_from_forgery except: :create
  before_action :set_anonymous_chat

  def create
    @message = @chat.anonymous_messages.build(message_params.merge(role: 'user'))
    
    if @message.save
      # Update chat title if it's the first message
      update_chat_title if @chat.anonymous_messages.count == 1
      
      # Get assistant response from FastAPI
      assistant_response = get_assistant_response(@message.content)
      
      if assistant_response
        @assistant_message = @chat.anonymous_messages.create!(
          content: assistant_response,
          role: 'assistant'
        )
        
        # Persist sources for the assistant message
        persist_sources_for_message(@assistant_message) if @sources.present?
        
        # Show signup invitation after first assistant response
        @show_signup_invitation = @chat.anonymous_messages.where(role: 'assistant').count == 1
      end

      respond_to do |format|
        format.json { render_json_response }
        format.turbo_stream { render 'messages/create' }
        format.html { redirect_to root_path }
      end
    else
      redirect_to root_path, alert: 'Chyba pri posielaní správy.'
    end
  end

  private

  def set_anonymous_chat
    session_id = session[:anonymous_chat_id] ||= SecureRandom.uuid
    @chat = AnonymousChat.find_or_create_by(session_id: session_id) do |chat|
      chat.title = "Miťo konverzácia"
    end
  end

  def message_params
    params.require(:anonymous_message).permit(:content)
  end

  def update_chat_title
    # Generate title from first message (first 50 characters)
    title = @message.content.truncate(50)
    @chat.update!(title: title)
  end

  def get_assistant_response(user_message)
    begin
      response = HTTP.timeout(30).post(
        'http://localhost:8000/api/chat',
        json: {
          message: user_message,
          session_id: @chat.session_id
        }
      )

      if response.status.success?
        response_data = JSON.parse(response.body)
        @sources = response_data['sources'] || []
        response_data['response']
      else
        @sources = []
        # Log the actual error for debugging
        error_body = response.body rescue "No response body"
        Rails.logger.error "FastAPI Error Response: #{response.status} - #{error_body}"
        
        # Provide a helpful temporary response
        "Ďakujem za vašu otázku o \"#{user_message}\". Momentálne riešim technické problémy s backend službou. Skúste to prosím znovu o chvíľu, alebo sa zaregistrujte na uloženie konverzácie."
      end
    rescue => e
      Rails.logger.error "FastAPI Connection Error: #{e.message}"
      @sources = []
      "Prepáčte, backend služba momentálne nie je dostupná. Pracujeme na oprave. Zaregistrujte sa prosím na uloženie vašej otázky a my vám odpovieme čo najskôr."
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

    if @assistant_message
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

    # Add signup invitation flag for anonymous users
    if @show_signup_invitation
      response_data[:show_signup_invitation] = true
    end

    # Add chat title if this is the first message
    if @chat.anonymous_messages.count == 1
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
end
