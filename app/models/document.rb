class Document < ApplicationRecord
  include Searchable, Extractable, FromEntry, FromEmailAddress

  belongs_to :source, polymorphic: true
  has_many :document_states, dependent: :destroy
  has_many :users, through: :document_states

  before_validation :format_attributes
  validates :content, length: { maximum: 500_000 }

  def authorized?
    return true if DocumentState.exists?(document: self, user: Current.user)
    return true if feed? && Subscription.exists?(feed: feed, user: Current.user)
    false
  end

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
end
