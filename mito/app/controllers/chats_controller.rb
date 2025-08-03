class ChatsController < ApplicationController
  before_action :authenticate_user!, only: [:index, :create, :destroy]
  before_action :set_chat, only: [:show]
  before_action :set_user_chats, only: [:index, :show]

  def index
    # Redirect to the main chat interface (same as root)
    @chat = current_user.chats.first || create_new_user_chat
    redirect_to chat_path(@chat)
  end

  def create
    @chat = current_user.chats.create!(title: "Nová konverzácia")
    redirect_to chat_path(@chat)
  end

  def destroy
    @chat = current_user.chats.find(params[:id])
    @chat.destroy!
    
    # Redirect to another chat or create a new one if no chats exist
    remaining_chat = current_user.chats.order(updated_at: :desc).first
    if remaining_chat
      redirect_to chat_path(remaining_chat), notice: 'Konverzácia bola odstránená.'
    else
      # Create a new chat if user has no chats left
      new_chat = create_new_user_chat
      redirect_to chat_path(new_chat), notice: 'Konverzácia bola odstránená. Vytvorená nová konverzácia.'
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: 'Konverzácia nebola nájdená.'
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

    if @chat
      @messages = user_signed_in? ? 
        @chat.messages.includes(:sources, :message_sources).ordered : 
        @chat.anonymous_messages.includes(:sources, :message_sources).ordered
    end
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
