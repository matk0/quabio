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
        
        # Show signup invitation after first assistant response
        @show_signup_invitation = @chat.anonymous_messages.where(role: 'assistant').count == 1
      end

      respond_to do |format|
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
        JSON.parse(response.body)['response']
      else
        # Log the actual error for debugging
        error_body = response.body rescue "No response body"
        Rails.logger.error "FastAPI Error Response: #{response.status} - #{error_body}"
        
        # Provide a helpful temporary response
        "Ďakujem za vašu otázku o \"#{user_message}\". Momentálne riešim technické problémy s backend službou. Skúste to prosím znovu o chvíľu, alebo sa zaregistrujte na uloženie konverzácie."
      end
    rescue => e
      Rails.logger.error "FastAPI Connection Error: #{e.message}"
      "Prepáčte, backend služba momentálne nie je dostupná. Pracujeme na oprave. Zaregistrujte sa prosím na uloženie vašej otázky a my vám odpovieme čo najskôr."
    end
  end
end
