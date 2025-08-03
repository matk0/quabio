class CreateSources < ActiveRecord::Migration[8.0]
  def change
    create_table :sources, id: :uuid do |t|
      t.string :title, null: false
      t.string :url, null: false
      t.text :excerpt
      t.text :chunk_text
      t.integer :chunk_size
      t.string :document_id
      t.json :metadata

      t.timestamps
    end
    
    add_index :sources, :url, unique: true
    add_index :sources, :title
    add_index :sources, :document_id
  end
end
