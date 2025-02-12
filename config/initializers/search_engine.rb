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

    self.initialize
    @client
  end

  def self.register_collection(klass)
    @collections_to_initialize ||= []
    @collections_to_initialize << klass
  end

  def self.initialize
    @collections_to_initialize.each do |klass|
      begin
        @client.collections[klass.search_collection_name].retrieve
      rescue Typesense::Error::ObjectNotFound
        klass.create_collection
      rescue Typesense::Error::HTTPStatus0Error => e
        Rails.logger.error "Unable to connect to Typesense: #{e.message}"
        raise
      end
    end
  end

  def self.reset
    @collections_to_initialize.each do |klass|
      begin
        @client.collections[klass.search_collection_name].delete
      rescue Typesense::Error::ObjectNotFound
        Rails.logger.info "Collection not found during reset"
      end
      self.initialize
    end
  end
end
