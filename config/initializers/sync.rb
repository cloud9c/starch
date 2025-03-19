# Rails.application.config.after_initialize do
#   begin
#     Rails.logger.info "Scheduling UpdateChannelsJob on startup"
#     UpdateChannelsJob.perform_later

#     Rails.logger.info "Attempting to sync search database with Typesense"
#     SearchEngine.sync_database
#   rescue => e
#     Rails.logger.error "Error during startup jobs: #{e.message}"
#     Rails.logger.error e.backtrace.join("\n")
#   end
# end
