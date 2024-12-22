class SpiderChannelJob < ApplicationJob
  include UrlNormalizer

  def perform(channel)
    @robots = Robots.new "StarchBot"
    discovered_urls = Set.new
    to_visit = Queue.new

    @base_url = "https://www.#{channel.domain}"

    return unless robot_allowed?(@base_url)

    initial_urls = fetch_sitemap || [ @base_url ]
    initial_urls.each { |url| to_visit << normalize_url(url) }

    while !to_visit.empty?
      current_url = to_visit.pop
      next if !robot_allowed?(current_url) || discovered_urls.include?(current_url)

      discovered_urls.add(current_url)

      new_urls = SpiderPageJob.perform_now(channel.id, current_url, channel.domain)
                 .reject { |url| discovered_urls.include?(url) }

      new_urls.each { |url| to_visit << url }
    end
  end

  def fetch_sitemap
    sitemap = SitemapParser.new("#{@base_url}/sitemap.xml", { recurse: true })

    begin
      sitemap.to_a.map { |url| normalize_url(url) }
    rescue RuntimeError => e
      nil if e.message.include?("Malformed sitemap")
    end
  end

  def robot_allowed?(url)
    if @robots
      @robots.allowed?(url)
    else
      true
    end
  end
end
