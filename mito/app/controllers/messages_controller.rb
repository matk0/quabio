class MessagesController < ApplicationController
  before_action :set_chat

  def create
    @message = @chat.messages.build(message_params.merge(role: 'user'))
    
    if @message.save
      # Update chat title if it's the first message
      update_chat_title if @chat.messages.count == 1
      
      # Get assistant response from FastAPI
      assistant_response = get_assistant_response(@message.content)
      
      if assistant_response
        @assistant_message = @chat.messages.create!(
          content: assistant_response,
          role: 'assistant'
        )
      end

      respond_to do |format|
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
      response = HTTP.timeout(30).post(
        'http://localhost:8000/api/chat',
        json: {
          message: user_message,
          session_id: @chat.id
        }
      )

      if response.status.success?
        JSON.parse(response.body)['response']
      else
        'Prepáčte, nastala chyba pri spracovaní vašej otázky. Skúste to znovu.'
      end
    rescue => e
      Rails.logger.error "FastAPI Error: #{e.message}"
      'Prepáčte, služba momentálne nie je dostupná. Skúste to neskôr.'
    end
  end
end
