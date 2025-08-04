class RenameModelNameToModelInModelPricings < ActiveRecord::Migration[8.0]
  def change
    rename_column :model_pricings, :model_name, :model
  end
end
