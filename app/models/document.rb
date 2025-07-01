class Document < ApplicationRecord
  include Searchable, Queryable, Extractable, FromEntry, FromEmailAddress

  belongs_to :source, polymorphic: true
  has_many :document_states, dependent: :destroy
  has_one :document_state, -> { where(user_id: Current.user.id) }, class_name: "DocumentState"
  has_many :users, through: :document_states

  before_validation :format_attributes
  validates :content, length: { maximum: 500_000 }

  PER_PAGE = 10

  require "image_size/uri"
  def self.find_thumbnail(html, min_width: 100, min_height: 100)
    doc = Nokogiri::HTML(html)

    images = doc.css("img")

    images.each do |image|
      src = image["src"]

      begin
        size = ImageSize.url(src).size
      rescue
        next
      end

      next if size.nil?
      width, height = size
      return src if width >= min_width && height >= min_height
    end

    nil
  end

  def format_attributes
    self.url = UrlUtils.normalize(url) if url.present?

    if content.present?
      sanitized_content = FormatUtils.format_html(content, url)
      self.content = sanitized_content
      self.thumbnail_url ||= Document.find_thumbnail(sanitized_content)
    end

    self.title = FormatUtils.format_text(title) if title.present?
    self.description = FormatUtils.format_text(description) if description.present?
    self.author = FormatUtils.format_text(author) if author.present?
  end
end
