class Resource < ApplicationRecord
  include Epub

  belongs_to :user

  has_one :document, as: :source, dependent: :destroy
  has_one_attached :file
  enum :mime_type, [ :text, :html, :pdf, :epub, :doc, :docx, :mobi ]

  validate :validate_user_total_storage
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
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document" => :docx,
    "application/x-mobipocket-ebook" => :mobi,
    "application/vnd.amazon.ebook" => :azw3
  }.freeze
  SUPPORTED_MIME_TYPES = MIME_TYPE_LOOKUP.keys.freeze

  FILE_SIZE_LIMIT = 100.megabytes

  require "zip"
  def serve_file(file_path)
    file.open do |tempfile|
      Zip::File.open(tempfile.path) do |zip_file|
        zip_file.each { |entry| puts "  #{entry.name}" }

        entry = zip_file.find_entry(file_path)
        return nil unless entry

        entry.get_input_stream.read
      end
    end
  end

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

    def validate_user_total_storage
      return unless file.attached? && user

      current_total = user.total_storage_used
      new_file_size = file.blob.byte_size

      if persisted? && file_previously_changed?
        old_blob = file.blob_was
        current_total -= old_blob.byte_size if old_blob
      end

      total_after_upload = current_total + new_file_size

      if total_after_upload > User::STORAGE_LIMIT
        remaining = User::STORAGE_LIMIT - current_total
        errors.add(:file, "would exceed storage limit. You have #{remaining / 1.megabyte}MB remaining of your #{User::STORAGE_LIMIT / 1.megabyte}MB limit")
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
