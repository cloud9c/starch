class Document < ApplicationRecord
  include Searchable, Queryable, Extractable, FromEntry, FromEmailAddress

  belongs_to :source, polymorphic: true
  has_many :document_states, dependent: :destroy
  has_one :document_state, -> { where(user_id: Current.user.id) }, class_name: "DocumentState"
  has_many :users, through: :document_states

  before_validation :normalize_attributes
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

  def normalize_attributes
    sanitized_content = FormatUtils.format_html(content, normalized_url)

    self.url = UrlUtils.normalize(url) if url.present?
    self.content = sanitized_content

    self.title = FormatUtils.format_text(title)
    self.description = FormatUtils.format_text(description)
    self.author = FormatUtils.format_text(author)

    unless thumbnail_url
      self.thumbnail_url = Document.find_thumbnail(sanitized_content)
    end
  end
end
