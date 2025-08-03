class Chat < ApplicationRecord
  belongs_to :user
  has_many :messages, dependent: :destroy

  validates :title, presence: true

  def display_title
    title.presence || "Nová konverzácia"
  end

  def last_message_at
    messages.maximum(:created_at) || created_at
  end
end
