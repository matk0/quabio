class Message < ApplicationRecord
  belongs_to :chat

  enum :role, { user: 'user', assistant: 'assistant' }

  validates :content, presence: true
  validates :role, presence: true

  scope :ordered, -> { order(:created_at) }
end
