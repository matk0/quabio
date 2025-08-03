class ChatsController < ApplicationController
  before_action :authenticate_user!, only: [:index]
  before_action :set_chat, only: [:show]
  before_action :set_user_chats, only: [:index, :show]

  def index
    @chats = current_user.chats.order(updated_at: :desc)
  end

  def show
    if user_signed_in?
      # Authenticated user flow
      if params[:id].blank?
        @chat = current_user.chats.first || create_new_user_chat
        redirect_to chat_path(@chat) and return if @chat.persisted? && params[:id].blank?
      end
      @message = Message.new
    else
      # Anonymous user flow - always show the main chat interface
      @chat = get_or_create_anonymous_chat
      @message = AnonymousMessage.new
    end

    @messages = @chat.messages.ordered if @chat
  end

  private

  def set_chat
    if user_signed_in? && params[:id].present?
      @chat = current_user.chats.find(params[:id])
    elsif !user_signed_in?
      @chat = get_or_create_anonymous_chat
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: 'Chat nenájdený.'
  end

  def set_user_chats
    if user_signed_in?
      @user_chats = current_user.chats.order(updated_at: :desc).limit(10)
    else
      @user_chats = []
    end
  end

  def create_new_user_chat
    current_user.chats.create!(title: "Nová konverzácia")
  end

  def get_or_create_anonymous_chat
    session_id = session[:anonymous_chat_id] ||= SecureRandom.uuid
    
    AnonymousChat.find_or_create_by(session_id: session_id) do |chat|
      chat.title = "Miťo konverzácia"
    end
  end
end
