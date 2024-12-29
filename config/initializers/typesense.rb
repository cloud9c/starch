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
      logger: Logger.new($stdout),
      log_level: Logger::INFO
    )
  end

  def self.initialize
    begin
      client.collections["documents"].retrieve
    rescue Typesense::Error::ObjectNotFound
      client.collections.create(Document.typesense_schema)
    rescue Typesense::Error::HTTPStatus0Error => e
      Rails.logger.warn "Unable to connect to Typesense: #{e.message}"
    end
  end

  def self.reset
    client.collections["documents"].delete
    self.initialize
  end
end

Rails.application.config.after_initialize do
  TypesenseClient.initialize
end
