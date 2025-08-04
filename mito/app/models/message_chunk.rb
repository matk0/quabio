class MessageChunk < ApplicationRecord
  belongs_to :chunk
  belongs_to :messageable, polymorphic: true
  
  validates :relevance_score, presence: true, 
            numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0 }
  validates :chunk_id, uniqueness: { scope: [:messageable_type, :messageable_id] }
  
  scope :ordered_by_relevance, -> { order(relevance_score: :desc) }
  scope :high_relevance, -> { where('relevance_score >= ?', 0.7) }
  scope :for_message_type, ->(type) { where(messageable_type: type) }
  
  # Helper method to get formatted relevance score
  def formatted_relevance_score
    sprintf("%.1f", relevance_score)
  end
end