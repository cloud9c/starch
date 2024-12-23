class SpiderPageJob < ApplicationJob
  include PageParsable

  def perform(channel_id, url)
    channel = Channel.find(channel_id)
    domain = channel.domain
    response = get_response(url)

    return if response.is_a?(HTTPX::ErrorResponse) || response.status != 200

    doc = Nokogiri::HTML(response.body)
    canonical_url = get_canonical(doc, response)

    return if Page.exists?(url: canonical_url) || doc.text.blank?

    Page.create(
      channel: channel,
      title: get_title(doc),
      description: get_description(doc),
      url: canonical_url,
      content: get_content(doc)
    )

    {
      candidates: doc.css("a").map { |a| get_absolute_url(a["href"], canonical_url) }.compact,
      canonical_url: canonical_url
    }
  end

  def get_response(url)
    response = HTTPX.get(url)
    return get_response(normalize_url(response.headers["location"])) if response.status == 301
    response
  end

  def get_canonical(doc, response)
    doc.at_css('link[rel="canonical"]')&.[]("href") || normalize_url(response.uri.to_s)
  end
end
