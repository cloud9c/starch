module TypesenseClient
  def self.client
    @client ||= Typesense::Client.new(
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
  end

  def self.initialize
    begin
      client.collections[Document::COLLECTION_NAME].retrieve
    rescue Typesense::Error::ObjectNotFound
      Document.create_collection
    rescue Typesense::Error::HTTPStatus0Error => e
      Rails.logger.error "Unable to connect to Typesense: #{e.message}"
      raise
    end
  end

  def self.reset
    begin
      client.collections[Document::COLLECTION_NAME].delete
    rescue Typesense::Error::ObjectNotFound
      Rails.logger.info "Collection not found during reset"
    end
    self.initialize
  end
end

Rails.application.config.after_initialize do
  TypesenseClient.initialize
end
