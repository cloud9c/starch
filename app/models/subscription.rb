class Subscription < ApplicationRecord
  include UserOwnable
  include Turbo::Broadcastable

  belongs_to :channel
  has_many :subscriptions_tags, dependent: :destroy
  has_many :tags, through: :subscriptions_tags

  has_many :entries, through: :channel
  has_many :documents, through: :entries

  after_destroy :remove_document_states

  validates :channel_id, presence: true, uniqueness: { scope: :user_id }

  def add_recent_entries
    recent_entries = channel.entries.recent

    recent_entries.each do |entry|
      document = entry.document
      DocumentState.create(
        user_id: user_id,
        document: document
      )
    end

    Rails.logger.debug "#{recent_entries.inspect}"
  end

  def remove_document_states
    DocumentState.where(user_id: user_id, document_id: documents.pluck(:id), status: :inbox).destroy_all
  end
end
