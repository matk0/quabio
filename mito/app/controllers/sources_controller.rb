class SourcesController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin
  before_action :set_source, only: [:show]

  def index
    @sources = Source.includes(:message_sources)
                    .left_joins(:message_sources)
                    .group('sources.id')
                    .select('sources.*, COUNT(message_sources.id) as usage_count')
                    .order('usage_count DESC, sources.created_at DESC')
                    .limit(50)

    @total_sources = Source.count
    @total_usage = MessageSource.count
    @most_used_source = Source.joins(:message_sources)
                             .group('sources.id')
                             .order('COUNT(message_sources.id) DESC')
                             .first
  end

  def show
    # Get the raw message sources for counting
    base_message_sources = @source.message_sources
                                  .joins("JOIN messages ON message_sources.messageable_id = messages.id AND message_sources.messageable_type = 'Message'")
                                  .joins("JOIN chats ON messages.chat_id = chats.id")
                                  .joins("JOIN users ON chats.user_id = users.id")
    
    # Get the detailed data for display
    @message_sources = base_message_sources
                      .includes(:messageable)
                      .select('message_sources.*, messages.content as message_content, messages.created_at as message_created_at, 
                              messages.variant, messages.comparison_group_id, chats.title as chat_title, 
                              chats.id as chat_id, users.email as user_email')
                      .order('message_sources.relevance_score DESC, messages.created_at DESC')

    # Calculate stats using the base query without the complex select
    @usage_stats = {
      total_uses: base_message_sources.count,
      unique_chats: base_message_sources.distinct.count('chats.id'),
      unique_users: base_message_sources.distinct.count('users.id'),
      avg_relevance: base_message_sources.average('message_sources.relevance_score') || 0.0,
      variants_used: base_message_sources.where.not('messages.variant' => nil).distinct.pluck('messages.variant')
    }
  end

  private

  def set_source
    @source = Source.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to sources_path, alert: 'Zdroj nenájdený.'
  end

  def ensure_admin
    unless current_user&.admin?
      redirect_to root_path, alert: 'Prístup zamietnutý. Potrebujete admin oprávnenia.'
    end
  end
end