class Document < ApplicationRecord
  include Searchable, Queryable, Extractable, FromEntry, FromEmailAddress

  belongs_to :source, polymorphic: true
  has_many :document_states, dependent: :destroy
  has_one :document_state, -> { where(user_id: Current.user.id) }, class_name: "DocumentState"
  has_many :users, through: :document_states

  before_validation :normalize_attributes
  validates :content, length: { maximum: 100_000 }

  PER_PAGE = 10

  def normalize_attributes
    normalized_url = UrlUtils.normalize(url) if url.present?
    sanitized_content = SanitizeUtils.clean_html(content, normalized_url)

    self.url = normalized_url
    self.content = sanitized_content

    self.title = TextUtils.html_to_text(title)
    self.description = TextUtils.html_to_text(description)
    self.author = TextUtils.html_to_text(author)

    unless thumbnail_url
      self.thumbnail_url = TextUtils.extract_thumbnail(sanitized_content)
    end
  end
end
