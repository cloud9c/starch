module TypesenseClient
  def self.client
    @client ||= Typesense::Client.new(
      nodes: [
        {
          host: "localhost",
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

  def self.create_collection_if_not_exists
    begin
      client.collections["pages"].retrieve
    rescue Typesense::Error::ObjectNotFound
      client.collections.create(Page.typesense_schema)
    end
  end
end

Rails.application.config.after_initialize do
  TypesenseClient.create_collection_if_not_exists
end
