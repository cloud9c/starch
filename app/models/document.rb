class Document < ApplicationRecord
  include Searchable, Extractable, FromSource, Renderable
  CONTENT_LIMIT = 500_000

  belongs_to :source, polymorphic: true
  belongs_to :user

  before_validation :format_attributes
  validates :content, length: { maximum: CONTENT_LIMIT }
  enum :status, [ :inbox, :later, :archive, :feed ]
  after_commit :cleanup_source, on: :destroy

  private
    def format_attributes
      self.url = UrlUtils.normalize(url) if url.present?

      if content.present?
        self.content = FormatUtils.format_html(content, url) unless email?
        self.content = content.truncate(CONTENT_LIMIT, separator: " ")
        self.thumbnail_url ||= FormatUtils.find_thumbnail(content)
      end

      self.title = FormatUtils.format_text(title) if title.present?
      self.author = FormatUtils.format_text(author) if author.present?

      if description.present?
        self.description = FormatUtils.format_text(description)
      elsif content.present?
        self.description = FormatUtils.extract_description(content)
      end
    end

    def cleanup_source
      resource.destroy if resource? && !resource.document
      sender.destroy if email? && !sender.documents.exists?
      feed.destroy if feed? && !feed.documents.exists?
    end
end
