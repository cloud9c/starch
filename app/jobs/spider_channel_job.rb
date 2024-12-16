class SpiderChannelJob < ApplicationJob
  require "spidr"
  require "nokogiri"

  def perform(channel)
    # Spidr.site("https://" + channel.domain, robots: true) do |agent|
    #   agent.every_html_page do |page|
    #     next if page.code != 200

    #     doc = page.doc
    #     # Remove script and style elements
    #     doc.css('script, style').remove

    #     Page.create!(
    #       channel: channel,
    #       title: page.title,
    #       description: page.at('meta[name="description"]'),
    #       link: page.url,
    #       content: doc.text.strip.gsub(/\s+/, ' ')
    #     )
    #   end
    # end
  end
end
