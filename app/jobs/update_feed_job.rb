class UpdateFeedJob < ApplicationJob
  def perform(channel)
    feed = FeedParser.get_feed(channel.feed_url)

    # feed.entries.each do |entry|
    #   puts "title: #{entry.title}"
    #   puts "published: #{entry.published}"
    #   puts "url: #{entry.url}"
    #   puts "id: #{entry.entry_id}"
    #   puts "summary: #{entry.summary}"
    #   puts "author: #{entry.author}"
    # end
  end
end
