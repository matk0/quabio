class Message < ApplicationRecord
  belongs_to :chat
  has_many :message_sources, as: :messageable, dependent: :destroy
  has_many :sources, through: :message_sources
  has_many :api_usages, dependent: :destroy

  enum :role, { user: 'user', assistant: 'assistant' }

  validates :content, presence: true
  validates :role, presence: true

  scope :ordered, -> { order(:created_at) }
  scope :comparison_messages, -> { where.not(comparison_group_id: nil) }
  scope :regular_messages, -> { where(comparison_group_id: nil) }
  scope :by_comparison_group, ->(group_id) { where(comparison_group_id: group_id) }
  
  # Helper method to get sources ordered by relevance
  def sources_by_relevance
    sources.includes(:message_sources)
           .where(message_sources: { messageable: self })
           .order('message_sources.relevance_score DESC')
  end
  
  # Check if this message is part of a comparison group
  def comparison_message?
    comparison_group_id.present?
  end
  
  # Get other messages in the same comparison group
  def comparison_siblings
    return Message.none unless comparison_message?
    Message.by_comparison_group(comparison_group_id).where.not(id: id)
  end
  
  # Get all messages in the comparison group (including self)
  def comparison_group_messages
    return Message.where(id: id) unless comparison_message?
    Message.by_comparison_group(comparison_group_id).order(:created_at)
  end
  
  # Check if this is the first message in a comparison group
  def first_in_comparison_group?
    return false unless comparison_message?
    comparison_group_messages.first == self
  end
  
  # Cost tracking methods
  def has_cost_data?
    total_cost_usd.present? || token_usage.present?
  end
  
  def formatted_cost
    return "N/A" unless total_cost_usd
    "$#{sprintf('%.4f', total_cost_usd)}"
  end
  
  def token_count
    return 0 unless token_usage
    token_usage['total_tokens'] || 0
  end
  
  def prompt_tokens
    return 0 unless token_usage
    token_usage['prompt_tokens'] || 0
  end
  
  def completion_tokens
    return 0 unless token_usage
    token_usage['completion_tokens'] || 0
  end
  
  def model_used
    return 'Unknown' unless token_usage
    token_usage['model'] || 'Unknown'
  end
end
