class Admin::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin
  
  def index
    @total_messages = Message.where(role: 'assistant').count
    @total_cost = Message.where(role: 'assistant').sum(:total_cost_usd) || 0.0
    @total_tokens = Message.where(role: 'assistant').sum("COALESCE((token_usage->>'total_tokens')::integer, 0)")
    
    # Recent usage (last 30 days)
    @recent_messages = Message.where(role: 'assistant')
                              .where('created_at >= ?', 30.days.ago)
                              .count
    @recent_cost = Message.where(role: 'assistant')
                          .where('created_at >= ?', 30.days.ago)
                          .sum(:total_cost_usd) || 0.0
    
    # Usage by model
    @usage_by_model = ApiUsage.joins(:message)
                              .group(:model)
                              .select('model, COUNT(*) as request_count, SUM(cost_usd) as total_cost, SUM(total_tokens) as total_tokens')
                              .order('total_cost DESC')
    
    # Daily usage for the last 30 days
    @daily_usage = ApiUsage.joins(:message)
                           .where('messages.created_at >= ?', 30.days.ago)
                           .group("DATE(messages.created_at)")
                           .select('DATE(messages.created_at) as date, COUNT(*) as requests, SUM(cost_usd) as cost, SUM(total_tokens) as tokens')
                           .order('date DESC')
    
    # Expensive queries (top 10)
    @expensive_queries = Message.where(role: 'assistant')
                                .where.not(total_cost_usd: nil)
                                .order(total_cost_usd: :desc)
                                .limit(10)
                                .includes(:chat)
    
    # Model pricing info
    @model_pricing = ModelPricing.active.order(:model)
  end
  
  private
  
  def ensure_admin
    redirect_to root_path, alert: 'Nemáte oprávnenie na prístup k tejto stránke.' unless current_user.admin?
  end
end