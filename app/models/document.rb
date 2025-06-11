class Document < ApplicationRecord
  include Searchable, Queryable, Extractable, FromEntry, FromEmailAddress

  belongs_to :source, polymorphic: true
  has_many :document_states, dependent: :destroy
  has_many :users, through: :document_states

  validates :content, length: { maximum: 100_000 }

  before_validation :normalize_attributes

  PER_PAGE = 10

  def normalize_attributes
    normalized_url = UrlUtils.normalize(url) if url.present?
    sanitized_content = SanitizeUtils.clean_html(content, normalized_url)

    self.url = normalized_url
    self.content = sanitized_content

    self.title = TextUtils.format_html(title)
    self.description = TextUtils.format_html(description)
    self.author = TextUtils.format_html(author)

    unless thumbnail_url
      self.thumbnail_url = TextUtils.extract_thumbnail(sanitized_content)
    end
  end
end
