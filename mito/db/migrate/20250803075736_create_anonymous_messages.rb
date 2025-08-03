class CreateAnonymousMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :anonymous_messages, id: :uuid do |t|
      t.references :anonymous_chat, null: false, foreign_key: true, type: :uuid
      t.text :content
      t.string :role

      t.timestamps
    end
  end
end
