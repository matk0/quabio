class CreateMessageChunks < ActiveRecord::Migration[8.0]
  def change
    create_table :message_chunks, id: :uuid do |t|
      t.references :chunk, null: false, foreign_key: true, type: :uuid
      t.references :messageable, polymorphic: true, null: false, type: :uuid
      t.decimal :relevance_score, precision: 4, scale: 3, null: false

      t.timestamps
    end
    
    add_index :message_chunks, [:chunk_id, :messageable_type, :messageable_id], 
              name: "index_message_chunks_uniqueness", unique: true
    add_index :message_chunks, :relevance_score
  end
end
