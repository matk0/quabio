class Chunk < ApplicationRecord
  belongs_to :source
  has_many :message_chunks, as: :messageable, dependent: :destroy
  has_many :messages, through: :message_chunks, source: :messageable, source_type: 'Message'
  has_many :anonymous_messages, through: :message_chunks, source: :messageable, source_type: 'AnonymousMessage'
  
  validates :content, presence: true
  validates :chunk_type, presence: true, inclusion: { in: %w[fixed semantic] }
  validates :chunk_size, presence: true, numericality: { greater_than: 0 }
  
  scope :fixed_size, -> { where(chunk_type: 'fixed') }
  scope :semantic, -> { where(chunk_type: 'semantic') }
  scope :ordered_by_relevance, -> { joins(:message_chunks).order('message_chunks.relevance_score DESC') }
  
  # Helper method to get all messages (both types)
  def all_messages
    message_chunks.includes(:messageable).map(&:messageable)
  end
  
  # Helper method to get formatted excerpt
  def formatted_excerpt
    return excerpt if excerpt.present?
    content.truncate(200)
  end
end