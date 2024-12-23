class SpiderChannelJob < ApplicationJob
  include PageParsable

  def perform(channel)
    origin = get_origin(channel.domain)
    return unless robot_allowed?(origin)

    @host = get_host(channel.domain)

    seeds = Set.new
    visited = Set.new
    queue = Queue.new

    seeds.merge(get_sitemap(origin))
    seeds.add(origin)
    seeds.each { |url| queue << normalize_url(url) }

    while !queue.empty?
      dequeue(queue, visited, channel)
    end
  end

  def has_same_host?(url)
    begin
      URI.parse(url).host == @host
    rescue URI::InvalidURIError
      false
    end
  end

  def dequeue(queue, visited, channel)
    current_url = queue.pop

    return if visited.include?(current_url)
    return unless robot_allowed?(current_url)

    visited.add(current_url)
    response = SpiderPageJob.perform_now(channel.id, current_url)

    return unless response

    visited.add(response[:canonical_url])
    Array(response[:candidates]).reject { |url| visited.include?(url) }
              .select { |url| has_same_host?(url) }
              .each { |url| queue << url }
  end
end
