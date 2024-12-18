class SpiderChannelJob < ApplicationJob
  def perform(channel)
    Spidr.site("https://" + channel.domain, robots: true) do |agent|
      agent.every_html_page do |page|
        begin
          next if page.code != 200
          doc = page.doc
          next if doc.text.blank? || page.title.to_s.strip.blank?

          doc.css("script, style").each(&:remove)

          description = doc.at('meta[name="description"]')&.attr("content").to_s.strip
          content = doc.text.strip.gsub(/\s+/, " ")[0..100000]

          Page.create!(
            channel: channel,
            title: page.title.to_s.strip,
            description: description,
            link: page.url,
            content: content
          )

        rescue StandardError => e
          Rails.logger.error("Error processing page #{page.url}: #{e.message}")
          next
        end
      end
    end
  end
end
