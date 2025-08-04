class Source < ApplicationRecord
  has_many :chunks, dependent: :destroy
  has_many :message_sources, dependent: :destroy
  has_many :messages, through: :message_sources, source: :messageable, source_type: 'Message'
  has_many :anonymous_messages, through: :message_sources, source: :messageable, source_type: 'AnonymousMessage'
  
  validates :title, presence: true
  validates :url, presence: true, uniqueness: true
  
  scope :with_chunks, -> { joins(:chunks) }
  scope :by_popularity, -> { left_joins(:message_sources).group(:id).order('COUNT(message_sources.id) DESC') }
  
  # Helper method to get all messages (both types)
  def all_messages
    message_sources.includes(:messageable).map(&:messageable)
  end
  
  # Helper method to get chunks ordered by relevance across all messages
  def chunks_by_relevance
    chunks.joins(:message_chunks)
          .select('chunks.*, MAX(message_chunks.relevance_score) as max_relevance_score')
          .group('chunks.id')
          .order('max_relevance_score DESC')
  end
  
  # Helper method to get total chunk count
  def chunk_count
    chunks.count
  end
  
  # Helper method to get unique message count that reference this source
  def message_count
    message_sources.distinct.count(:messageable_id)
  end
end
