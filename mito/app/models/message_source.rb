class MessageSource < ApplicationRecord
  belongs_to :source
  belongs_to :messageable, polymorphic: true
  
  validates :relevance_score, presence: true, numericality: { 
    greater_than_or_equal_to: 0.0, 
    less_than_or_equal_to: 1.0 
  }
  
  # Ensure unique combination of source and messageable
  validates :source_id, uniqueness: { 
    scope: [:messageable_type, :messageable_id] 
  }
  
  scope :ordered_by_relevance, -> { order(relevance_score: :desc) }
end
