class ApiUsage < ApplicationRecord
  belongs_to :message
  
  validates :model, presence: true, length: { maximum: 50 }
  validates :prompt_tokens, presence: true, numericality: { greater_than: 0 }
  validates :completion_tokens, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_tokens, presence: true, numericality: { greater_than: 0 }
  validates :cost_usd, presence: true, numericality: { greater_than: 0 }
  validates :request_timestamp, presence: true
  validates :response_time_ms, numericality: { greater_than: 0 }, allow_nil: true
  
  scope :by_model, ->(model) { where(model: model) }
  scope :by_date_range, ->(start_date, end_date) { where(request_timestamp: start_date..end_date) }
  scope :recent, -> { order(request_timestamp: :desc) }
  scope :expensive, -> { order(cost_usd: :desc) }
  
  # Calculate total cost for a collection
  scope :total_cost, -> { sum(:cost_usd) }
  scope :total_tokens, -> { sum(:total_tokens) }
  
  # Group by time periods
  scope :by_day, -> { group("DATE(request_timestamp)") }
  scope :by_month, -> { group("DATE_TRUNC('month', request_timestamp)") }
  
  def cost_per_token
    return 0 if total_tokens.zero?
    cost_usd / total_tokens
  end
  
  def response_time_seconds
    return nil unless response_time_ms
    response_time_ms / 1000.0
  end
end