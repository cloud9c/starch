class Upload < ApplicationRecord
  belongs_to :user

  has_one :document, as: :source, dependent: :destroy
  has_one_attached :file
  enum :file_type, [ :text, :html, :pdf, :epub, :doc, :docx ]

  validates :file, presence: true
  validate :validate_file_properties
  before_create :set_file_type
  after_create :create_document_for_user
  before_destroy :dont_purge_file_if_shared

  CONTENT_TO_FILE_TYPE_MAP = {
    "text/plain" => :text,
    "text/html" => :html,
    "application/pdf" => :pdf,
    "application/epub+zip" => :epub,
    "application/msword" => :doc,
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document" => :docx
  }.freeze
  SUPPORTED_CONTENT_TYPE = CONTENT_TO_FILE_TYPE_MAP.keys.freeze
  FILE_SIZE_LIMIT = 10.megabytes

  private
    def validate_file_properties
      return unless file.attached?

      unless SUPPORTED_CONTENT_TYPE.include?(file.blob.content_type)
        errors.add(:file, "must be a supported file type")
      end

      if file.blob.byte_size > FILE_SIZE_LIMIT
        errors.add(:file, "must be less than #{FILE_SIZE_LIMIT / 1.megabyte}MB")
      end
    end

    def set_file_type
      return unless file.attached?
      self.file_type = CONTENT_TO_FILE_TYPE_MAP[file.blob.content_type]
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
