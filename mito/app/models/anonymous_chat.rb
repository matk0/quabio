class AnonymousChat < ApplicationRecord
  has_many :anonymous_messages, dependent: :destroy

  validates :session_id, presence: true, uniqueness: true
  validates :title, presence: true

  def display_title
    title.presence || "Nová konverzácia"
  end

  def last_message_at
    anonymous_messages.maximum(:created_at) || created_at
  end
  
  def messages
    anonymous_messages
  end
end
