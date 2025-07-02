module Document::Extractable
  extend ActiveSupport::Concern

  def extracted_data
    return {} unless url

    cache_key = "#{cache_key_with_version}/extracted_data"
    result = Rails.cache.fetch(cache_key, expires_in: 7.day) do
      extract_data_from_url(url)
    end

    result
  end

  def with_view_preferences
    return self unless should_extract

    preferences = {
      thumbnail_url: extracted_data[:thumbnail_url],
      content: extracted_data[:content],
      published_at: published_at || extracted_data[:published_at],
      title: title || extracted_data[:title],
      author: author || extracted_data[:author]
    }.compact

    preferences.each do |attr, value|
      self[attr] = value unless value.nil?
    end

    self
  end

  private

  def should_extract
    if self[:view_extracted].present?
      ActiveModel::Type::Boolean.new.cast(self[:view_extracted])
    elsif is_a?(Entry)
      subscription = feed&.subscriptions&.find { |s| s.user_id == Current.user.id }
      subscription&.view_extracted
    end
  end

  def extract_data_from_url(url)
    parsed_data = ReadingParser.extract(url)
    return {} unless parsed_data

    content = FormatUtils.format_html(parsed_data["content"], url)

    result = {
      content: content,
      thumbnail_url: FormatUtils.find_thumbnail(content),
      title: FormatUtils.format_text(parsed_data["title"]),
      author: FormatUtils.format_text(parsed_data["byline"]),
      published_at: (DateTime.parse(parsed_data["publishedTime"]) rescue nil)
    }

    result.compact
  end
end
