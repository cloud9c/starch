module TypesenseClient
  def self.client
    @client ||= Typesense::Client.new(
      nodes: [
        {
          host: Rails.env.production? ? "starch-typesense" : "localhost",
          port: 8108,
          protocol: "http"
        }
        # Uncomment if starting a 3-node cluster, using Option 2 under Setup instructions above
        # {
        #   host: 'localhost',
        #   port: 7108,
        #   protocol: 'http'
        # },
        # {
        #   host: 'localhost',
        #   port: 9108,
        #   protocol: 'http'
        # }
      ],
      # If this optional key is specified, requests are always sent to this node first if it is healthy
      #   before falling back on the nodes mentioned in the `nodes` key. This is useful when running a distributed set of search clusters.
      # 'nearest_node': {
      #   'host': 'localhost',
      #   'port': '8108',
      #   'protocol': 'http'
      # },
      api_key: "xyz",
      num_retries: 10,
      healthcheck_interval_seconds: 1,
      retry_interval_seconds: 0.01,
      connection_timeout_seconds: 10,
      logger: Rails.logger,
      log_level: Logger::INFO
    )
  end

  def self.initialize
    begin
      client.collections["pages"].retrieve
    rescue Typesense::Error::ObjectNotFound
      client.collections.create(Page.typesense_schema)
    rescue Typesense::Error::HTTPStatus0Error => e
      Rails.logger.warn "Unable to connect to Typesense: #{e.message}"
    end
  end

  def self.reindex
    client.collections["pages"].delete
    self.initialize

    Page.find_each(batch_size: 1000) do |page|
      page.index_in_typesense
    rescue => e
      Rails.logger.error "Failed to index page #{page.id}: #{e.message}"
    end
  end
end

Rails.application.config.after_initialize do
  TypesenseClient.initialize
end
