class CreateModelPricing < ActiveRecord::Migration[8.0]
  def change
    create_table :model_pricings, id: :uuid do |t|
      t.string :model_name, null: false, limit: 50
      t.decimal :input_cost_per_1k_tokens, precision: 10, scale: 6, null: false
      t.decimal :output_cost_per_1k_tokens, precision: 10, scale: 6, null: false
      t.date :effective_date, null: false
      t.boolean :is_active, default: true, null: false
      t.timestamps
    end

    add_index :model_pricings, :model_name
    add_index :model_pricings, :effective_date
    add_index :model_pricings, :is_active
    add_index :model_pricings, [:model_name, :is_active], unique: true, where: "is_active = true"
  end
end
