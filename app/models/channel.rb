class Channel < ApplicationRecord
  has_many :entries, dependent: :destroy
  has_many :documents, through: :entries, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :users, through: :subscriptions

  validates :feed_url, presence: true, uniqueness: true

  after_create :schedule_initial_update

  def update_feed_content
    headers = {}
    headers["If-Modified-Since"] = self.polled_at.httpdate if self.polled_at
    headers["If-None-Match"] = self.etag if self.etag
    
    response = HttpUtilities.get(self.feed_url, headers)
    return false unless response
    
    self.polled_at = Time.current
    self.etag = response.headers[:Etag]
    
    return false if response.status == 304
    
    self.feed_content = HttpUtilities.body_to_s(response)
    save!
    
    true
  end

  def poll(syndicate)
    result = EntryUtilities.get_new_and_updated(self.feed_url, self.feed_content)

    add_new_entries(result[:new], syndicate)
    update_entries(result[:updated])
  end

  def update_metadata
    feed = FeedUtilities.parse(self.feed_content) rescue nil
    return unless feed

    attributes = {}

    attributes[:title] = feed.title if feed.respond_to?(:title)
    attributes[:description] = feed.description if feed.respond_to?(:description)
    attributes[:url] = HttpUtilities.normalize(
      (feed.url if feed.respond_to?(:url)) || URI(self.feed_url).host
    )
    attributes[:icon] = HttpUtilities.get_icon(self.feed_url) if feed.respond_to?(:feed_url)
    attributes[:feed_url] = feed.feed_url if feed.respond_to?(:feed_url) && feed.feed_url

    update_columns(attributes) unless attributes.empty?
  end

  private

  def schedule_initial_update
    UpdateChannelJob.perform_now(id, syndicate=false)
  end

  def add_new_entries(new_entries, syndicate)
    new_entries.each do |entry|
      ActiveRecord::Base.transaction do
        document = Document.create!(
          title: entry.title,
          description: EntryUtilities.decode_text(entry.summary),
          author: entry.author,
          published_at: entry.published,
          url: entry.url,
          content: entry.content,
        )
        Entry.create!(
          document: document,
          channel: self,
          syndicate: syndicate,
        )
      end
    end
  end

  def update_entries(updated_entries)
    updated_entries.each do |entry|
      stable_id = get_stable_id(self.feed_url, entry)
      existing_entry = Entry.find_by(stable_id: stable_id)
      
      if existing_entry
        ActiveRecord::Base.transaction do
          existing_entry.document.update!(
            title: entry.title,
            description: entry.summary,
            author: entry.author,
            published_at: entry.published,
            content: entry.content
          )
        end
      else
        logger.warn "Could not find existing entry with stable_id: #{stable_id}"
      end
    end
  end
end
