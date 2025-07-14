class Entry < ApplicationRecord
  include Identifiable

  belongs_to :feed
  has_many :documents, as: :source, dependent: :destroy
  has_many :subscriptions, through: :feed
  attr_accessor :parsed_entry

  before_validation :add_attributes_from_parsed_entry
  validates :stable_id, presence: true, uniqueness: true
  validates :feed, presence: true
  after_create :add_to_inbox

  scope :recent, ->(limit = 5) { order(published_at: :desc).limit(limit).reverse }

  private
    def add_attributes_from_parsed_entry
      return unless parsed_entry.present?

      self.stable_id = Entry.get_stable_id(feed.feed_url, parsed_entry)
      self.published_at = parsed_entry.published || Time.current
    end

    def add_to_inbox
      return unless parsed_entry.present?

      document_attributes = Entry.extract_document_attributes(parsed_entry)
      return if document_attributes[:published_at] < feed.created_at

      users = subscriptions.to_inbox.includes(:user).map(&:user).uniq
      users.each do |user|
        documents.create!(**document_attributes,
          status: :inbox,
          user_id: user.id)
      end
    end

    def self.extract_document_attributes(parsed_entry)
      {
        title: parsed_entry.title,
        content: parsed_entry.content || parsed_entry.summary,
        description: (parsed_entry.summary && parsed_entry.content) ? parsed_entry.summary : nil,
        author: parsed_entry.author,
        published_at: parsed_entry.published,
        url: parsed_entry.url,
        thumbnail_url: parsed_entry.try(:media_thumbnail_url)
      }.compact
    end
end
