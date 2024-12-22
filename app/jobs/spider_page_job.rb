class SpiderPageJob < ApplicationJob
  include UrlNormalizer
  
  def perform(channel_id, url, domain)
    begin
      normalized_url = normalize_url(url)
      return [] if Page.exists?(link: normalized_url)

      channel = Channel.find(channel_id)
      response = HTTPX.get(url)
      doc = Nokogiri::HTML(response.body)

      return [normalize_url(response.headers['location'])] if response.status == 301
      return [] if response.status != 200 || doc.text.blank?

      doc.css("script, style").each(&:remove)

      description = doc.at('meta[name="description"]')&.attr("content").to_s.strip
      content = doc.text.strip.gsub(/\s+/, " ")[0..100000]
      title = doc.at('title')&.inner_text

      Page.create!(
        channel: channel,
        title: title.to_s.strip,
        description: description,
        link: normalized_url,
        content: content
      )

      get_urls(doc, domain)
    rescue => e
      Rails.logger.error("Error processing page #{url}: #{e.message}")
      []
    end
  end

  def get_urls(doc, domain)
    base_url = "https://#{domain}"

    absolute_urls = doc.css('a').map { |link| 
      href = link['href']
      uri = URI.join(base_url, href) rescue nil
      normalize_url uri.to_s if uri && uri.host == domain
    }.compact

    absolute_urls
  end
end
