class Document < ApplicationRecord
  include Searchable, Extractable, FromEntry, FromEmail, FromUpload

  belongs_to :source, polymorphic: true
  belongs_to :user

  before_validation :format_attributes
  validates :content, length: { maximum: 500_000 }
  validates :status, presence: true
  enum :status, [ :inbox, :later, :archive ]
  after_commit :cleanup_source, on: :destroy

  def format_attributes
    self.url = UrlUtils.normalize(url) if url.present?

    if content.present?
      sanitized_content = FormatUtils.format_html(content, url)
      self.content = sanitized_content
      self.thumbnail_url ||= FormatUtils.find_thumbnail(sanitized_content)
    end

    self.title = FormatUtils.format_text(title) if title.present?
    self.author = FormatUtils.format_text(author) if author.present?

    if description.present?
      self.description = FormatUtils.format_text(description)
    else
      self.description = FormatUtils.extract_description(content)
    end
  end

  private
    def cleanup_source
      upload.destroy if upload? && !upload.documents.exists?
      sender.destroy if email? && !sender.documents.exists?
    end
end
