class ModelPricing < ApplicationRecord
  validates :model, presence: true, length: { maximum: 50 }
  validates :input_cost_per_1k_tokens, presence: true, numericality: { greater_than: 0 }
  validates :output_cost_per_1k_tokens, presence: true, numericality: { greater_than: 0 }
  validates :effective_date, presence: true
  validates :model, uniqueness: { scope: :is_active, conditions: -> { where(is_active: true) } }
  
  scope :active, -> { where(is_active: true) }
  scope :for_model, ->(model) { where(model: model) }
  scope :current, -> { where(effective_date: ..Date.current) }
  
  # Get current pricing for a model
  def self.current_pricing_for(model)
    active.for_model(model).current.order(effective_date: :desc).first
  end
  
  # Calculate cost for token usage
  def calculate_cost(prompt_tokens, completion_tokens)
    input_cost = (prompt_tokens / 1000.0) * input_cost_per_1k_tokens
    output_cost = (completion_tokens / 1000.0) * output_cost_per_1k_tokens
    input_cost + output_cost
  end
  
  # Deactivate this pricing (when updating)
  def deactivate!
    update!(is_active: false)
  end
  
  # Create or update pricing for a model
  def self.set_pricing(model, input_cost, output_cost, effective_date = Date.current)
    # Deactivate existing active pricing
    active.for_model(model).update_all(is_active: false)
    
    # Create new pricing
    create!(
      model: model,
      input_cost_per_1k_tokens: input_cost,
      output_cost_per_1k_tokens: output_cost,
      effective_date: effective_date,
      is_active: true
    )
  end
end