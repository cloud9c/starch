class CleanupOrphanedFilesJob < ApplicationJob
  queue_as :default

  def perform(dry_run: true)
    Rails.logger.info "Starting orphaned files cleanup (dry_run: #{dry_run})"

    cleanup_orphaned_blobs(dry_run)
    cleanup_orphaned_attachments(dry_run)

    Rails.logger.info "Orphaned files cleanup completed"
  end

  private

  def cleanup_orphaned_blobs(dry_run)
    # Find blobs without any attachments, older than 1 day
    orphaned_blobs = ActiveStorage::Blob
      .left_joins(:attachments)
      .where(active_storage_attachments: { id: nil })
      .where("active_storage_blobs.created_at < ?", 1.day.ago)

    Rails.logger.info "Found #{orphaned_blobs.count} orphaned blobs"

    orphaned_blobs.find_each do |blob|
      Rails.logger.info "Orphaned blob: #{blob.id} - #{blob.filename} (#{blob.byte_size} bytes) - Created: #{blob.created_at}"

      unless dry_run
        begin
          blob.purge
          Rails.logger.info "Purged blob #{blob.id}"
        rescue => e
          Rails.logger.error "Failed to purge blob #{blob.id}: #{e.message}"
        end
      end
    end
  end

  def cleanup_orphaned_attachments(dry_run)
    # Find Resource attachments pointing to non-existent resources
    orphaned_attachments = ActiveStorage::Attachment
      .where(record_type: "Resource")
      .where.not(record_id: Resource.pluck(:id))

    Rails.logger.info "Found #{orphaned_attachments.count} orphaned Resource attachments"

    orphaned_attachments.find_each do |attachment|
      Rails.logger.info "Orphaned attachment: #{attachment.id} - Record ID: #{attachment.record_id} - Blob: #{attachment.blob_id}"

      unless dry_run
        begin
          # This will also purge the associated blob if it's not used elsewhere
          attachment.purge
          Rails.logger.info "Purged attachment #{attachment.id}"
        rescue => e
          Rails.logger.error "Failed to purge attachment #{attachment.id}: #{e.message}"
        end
      end
    end
  end
end
