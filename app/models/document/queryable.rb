module Document::Queryable
  extend ActiveSupport::Concern

  class_methods do
    def query(user_id, options = {})
      query = Document
        .includes(:document_state)
        .joins(
        "LEFT JOIN entries ON documents.source_type = 'Entry' AND documents.source_id = entries.id")
        .joins(
        "LEFT JOIN feeds ON entries.feed_id = feeds.id")
        .joins(
        "LEFT JOIN subscriptions ON feeds.id = subscriptions.feed_id")

      if options[:page].present?
        query = query.limit(Document::PER_PAGE)
                     .offset((options[:page] - 1) * Document::PER_PAGE)
      end

      if options[:status].present?
        query = query.where(document_state: { status: options[:status] })

        if options[:status] == :inbox
          query = query.order("document_state.read" => :asc)
        end
      elsif options[:ids].present?
        query = query.where(id: options[:ids])
      elsif options[:subscription].present?
        query = query.where(subscriptions: { id: options[:subscription] })
      else
        query = query.where(subscriptions: { user_id: user_id })
      end

      query = query.order("documents.published_at" => :desc)
                   .select("documents.*, subscriptions.view_extracted").distinct

      query.map do |doc|
        doc.with_view_preferences
          .with_description
      end
    end
  end

  def with_description
    return self if description.present?

    text = TextUtils.html_to_text(content)

    if text.present?
      self.description = text.strip.gsub(/\s+/, " ")[0...300]
    end

    self
  end
end
