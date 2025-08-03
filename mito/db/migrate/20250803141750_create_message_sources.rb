class CreateMessageSources < ActiveRecord::Migration[8.0]
  def change
    create_table :message_sources, id: :uuid do |t|
      t.references :source, null: false, foreign_key: true, type: :uuid
      t.references :messageable, polymorphic: true, null: false, type: :uuid
      t.decimal :relevance_score, precision: 4, scale: 3, null: false

      t.timestamps
    end
    
    add_index :message_sources, [:messageable_type, :messageable_id]
    add_index :message_sources, :relevance_score
    add_index :message_sources, [:source_id, :messageable_type, :messageable_id], 
              unique: true, name: 'index_message_sources_uniqueness'
  end
end
