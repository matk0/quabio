class AddCostFieldsToMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :messages, :total_cost_usd, :decimal, precision: 10, scale: 6
    add_column :messages, :token_usage, :jsonb
    
    add_index :messages, :total_cost_usd
    add_index :messages, :token_usage, using: :gin
  end
end
