class User < ApplicationRecord
  include Authentication, Billable, Emailable

  has_many :subscriptions, dependent: :destroy
  has_many :feeds, through: :subscriptions
  has_many :documents, dependent: :destroy
  has_many :webauthn_credentials, dependent: :destroy
  has_many :resources, dependent: :destroy

  normalizes :email_address, with: ->(email_address) { email_address.strip.downcase }
  validates :email_address,
            presence: true,
            uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }

  scope :unverified, -> { where(verified_at: nil) }

  STORAGE_LIMIT = 1000.megabytes

  def total_storage_used
    resource_storage = resources.joins(file_attachment: :blob)
                                .sum("active_storage_blobs.byte_size")

    document_storage = documents.joins(file_attachment: :blob)
                                .sum("active_storage_blobs.byte_size")

    resource_storage + document_storage
  end
end
