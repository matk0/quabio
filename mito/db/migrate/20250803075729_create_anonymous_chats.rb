class CreateAnonymousChats < ActiveRecord::Migration[8.0]
  def change
    create_table :anonymous_chats, id: :uuid do |t|
      t.string :session_id
      t.string :title

      t.timestamps
    end
  end
end
