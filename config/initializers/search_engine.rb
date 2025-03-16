module SearchEngine
  def self.client
    return @client if @client

    @client = Typesense::Client.new(
      nodes: [
        {
          host: Rails.env.production? ? "starch-typesense" : "localhost",
          port: 8108,
          protocol: "http"
        }
      ],
      api_key: "xyz",
      num_retries: 10,
      healthcheck_interval_seconds: 1,
      retry_interval_seconds: 0.01,
      connection_timeout_seconds: 10,
      logger: Rails.logger,
      log_level: Rails.env.production? ? Logger::INFO : Logger::DEBUG
    )

    initialize_collections
    @client
  end

  def self.register_collection(klass)
    @collections_to_initialize ||= []
    @collections_to_initialize << klass
  end

  def self.initialize_collections
    return unless @collections_to_initialize

    @collections_to_initialize.each do |klass|
      begin
        client.collections[klass.search_collection_name].retrieve
        Rails.logger.info "Collection '#{klass.search_collection_name}' exists in Typesense"
      rescue Typesense::Error::ObjectNotFound
        Rails.logger.info "Creating collection '#{klass.search_collection_name}' in Typesense"
        klass.create_search_collection
      rescue Typesense::Error::HTTPStatus0Error => e
        Rails.logger.error "Unable to connect to Typesense: #{e.message}"
        raise
      end
    end
  end

  def self.sync_database
    return unless @collections_to_initialize

    @collections_to_initialize.each do |klass|
      begin
        begin
          client.collections[klass.search_collection_name].retrieve
        rescue Typesense::Error::ObjectNotFound
          klass.create_search_collection
        end

        Rails.logger.info "Syncing #{klass.name} records to Typesense..."

        klass.find_in_batches(batch_size: 100) do |batch|
          batch.each do |record|
            begin
              record.upsert_search_index
              print "."
            rescue => e
              Rails.logger.error "Error indexing #{klass.name} ##{record.id}: #{e.message}"
            end
          end
        end

        puts
        Rails.logger.info "#{klass.name} sync complete"
      rescue => e
        Rails.logger.error "Error syncing #{klass.name}: #{e.message}"
      end
    end

    Rails.logger.info "Database sync with Typesense complete"
    true
  end

  def self.reset
    return unless @collections_to_initialize

    @collections_to_initialize.each do |klass|
      begin
        client.collections[klass.search_collection_name].delete
        Rails.logger.info "Collection '#{klass.search_collection_name}' deleted from Typesense"
      rescue Typesense::Error::ObjectNotFound
        Rails.logger.info "Collection '#{klass.search_collection_name}' not found during reset"
      end
    end

    initialize_collections
  end
end

Rails.application.config.to_prepare do
  SearchEngine.register_collection(Document)
end
