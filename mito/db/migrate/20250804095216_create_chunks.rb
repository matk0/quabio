class CreateChunks < ActiveRecord::Migration[8.0]
  def change
    create_table :chunks, id: :uuid do |t|
      t.references :source, null: false, foreign_key: true, type: :uuid
      t.text :content, null: false
      t.text :excerpt
      t.integer :chunk_size
      t.string :chunk_type, limit: 20
      t.string :document_id
      t.jsonb :metadata

      t.timestamps
    end
    
    add_index :chunks, :chunk_type
    add_index :chunks, :document_id
    add_index :chunks, :chunk_size
    add_index :chunks, :metadata, using: :gin
  end
end
