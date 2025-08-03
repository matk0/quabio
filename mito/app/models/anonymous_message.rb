class AnonymousMessage < ApplicationRecord
  belongs_to :anonymous_chat
  has_many :message_sources, as: :messageable, dependent: :destroy
  has_many :sources, through: :message_sources

  enum :role, { user: 'user', assistant: 'assistant' }

  validates :content, presence: true
  validates :role, presence: true

  scope :ordered, -> { order(:created_at) }
  
  # Helper method to get sources ordered by relevance
  def sources_by_relevance
    sources.joins(:message_sources)
           .where(message_sources: { messageable: self })
           .order('message_sources.relevance_score DESC')
  end
end
