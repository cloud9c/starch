module Document::Queryable
  extend ActiveSupport::Concern

  class_methods do
    def query(user_id, options = {})
      query = Document.joins(
        "LEFT JOIN entries ON documents.source_type = 'Entry' AND documents.source_id = entries.id"
      ).joins(
        "LEFT JOIN feeds ON entries.feed_id = feeds.id"
      ).joins(
        "LEFT JOIN subscriptions ON feeds.id = subscriptions.feed_id"
      )

      if options[:page].present?
        query = query.limit(Document::PER_PAGE)
                    .offset((options[:page] - 1) * Document::PER_PAGE)
      end

      if options[:status].present?
        query = query.joins(:document_states)
                    .where(document_states: { user_id: user_id, status: options[:status] })
                    .order("document_states.read" => :asc)

        query = query.select("document_states.read")
      elsif options[:ids].present?
        query = query.where(id: options[:ids])
      elsif options[:subscription].present?
        query = query.where(subscriptions: { id: options[:subscription] })
      else
        query = query.where(subscriptions: { user_id: user_id })
      end

      query = query.order("documents.published_at" => :desc)

      query = query.select("documents.*, subscriptions.view_extracted").distinct

      query.map do |doc|
        doc.with_view_preferences(skip_wait: true)
          .with_description
      end
    end
  end

  def with_description
    unless self[:description].present?
      self[:description] = EntryUtils.format_description(content)
    end

    self
  end

  def with_view_preferences(skip_wait: false)
    return self unless entry? # TODO: REFACTOR TO NOT RELY ON ENTRY

    should_extract =
      if self[:view_extracted].present?
        ActiveModel::Type::Boolean.new.cast(self[:view_extracted])
      else
        subscription = feed&.subscriptions&.find { |s| s.user_id == Current.user.id }
        subscription&.view_extracted
      end

    if !should_extract
      self.description = EntryUtils.format_description(content)
      return self
    elsif skip_wait && !Rails.cache.exist?("#{cache_key_with_version}/extracted_data")
      ExtractDocumentJob.perform_later(self.id)
      return self
    end

    preferences = {
      thumbnail_url: extracted_data[:thumbnail_url],
      content: extracted_data[:content],
      published_at: self.published_at || extracted_data[:published_at],
      title: self.title || extracted_data[:title],
      author: self.author || extracted_data[:author]
    }.compact

    preferences.each do |attr, value|
      self[attr] = value unless value.nil?
    end

    self
  end
end
