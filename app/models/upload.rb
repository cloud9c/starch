class Upload < ApplicationRecord
  belongs_to :user

  has_one :document, as: :source, dependent: :destroy
  has_one_attached :file
  enum :mime_type, [ :text, :html, :pdf, :epub, :doc, :docx ]

  validates :file, presence: true
  validate :validate_file_properties
  before_create :set_mime_type
  after_create :create_document_for_user
  before_destroy :dont_purge_file_if_shared

  MIME_TYPE_LOOKUP = {
    "text/plain" => :text,
    "text/html" => :html,
    "application/pdf" => :pdf,
    "application/epub+zip" => :epub,
    "application/msword" => :doc,
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document" => :docx
  }.freeze
  SUPPORTED_MIME_TYPES = MIME_TYPE_LOOKUP.keys.freeze
  FILE_SIZE_LIMIT = 10.megabytes

  private
    def validate_file_properties
      return unless file.attached?

      unless SUPPORTED_MIME_TYPES.include?(file.blob.content_type)
        errors.add(:file, "must be a supported file type")
      end

      if file.blob.byte_size > FILE_SIZE_LIMIT
        errors.add(:file, "must be less than #{FILE_SIZE_LIMIT / 1.megabyte}MB")
      end
    end

    def set_mime_type
      return unless file.attached?
      self.mime_type = MIME_TYPE_LOOKUP[file.blob.content_type]
    end

    def create_document_for_user
      create_document!(
        title: file.blob.filename.to_s,
        status: :inbox,
        published_at: Time.current,
        user: user
      )
    end

    def dont_purge_file_if_shared
      return unless file.attached?

      if file.blob.attachments.count > 1
        file.detach
      end
    end
end
