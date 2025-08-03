class Source < ApplicationRecord
  has_many :message_sources, dependent: :destroy
  has_many :messages, through: :message_sources, source: :messageable, source_type: 'Message'
  has_many :anonymous_messages, through: :message_sources, source: :messageable, source_type: 'AnonymousMessage'
  
  validates :title, presence: true
  validates :url, presence: true, uniqueness: true
  
  # Helper method to get all messages (both types)
  def all_messages
    message_sources.includes(:messageable).map(&:messageable)
  end
end
