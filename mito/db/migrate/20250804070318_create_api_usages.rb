class CreateApiUsages < ActiveRecord::Migration[8.0]
  def change
    create_table :api_usages, id: :uuid do |t|
      t.references :message, null: false, foreign_key: true, type: :uuid
      t.string :model, null: false, limit: 50
      t.integer :prompt_tokens, null: false
      t.integer :completion_tokens, null: false
      t.integer :total_tokens, null: false
      t.decimal :cost_usd, precision: 10, scale: 6, null: false
      t.timestamp :request_timestamp, null: false
      t.integer :response_time_ms
      t.timestamps
    end

    add_index :api_usages, :model
    add_index :api_usages, :request_timestamp
    add_index :api_usages, :cost_usd
  end
end
