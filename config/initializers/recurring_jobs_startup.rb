# config/initializers/recurring_jobs_startup.rb
Rails.application.config.after_initialize do
  if defined?(Rails::Server) || defined?(Puma) || defined?(SolidQueue::CLI)
    # Load recurring jobs from configuration
    begin
      recurring_config_path = ENV["SOLID_QUEUE_RECURRING_SCHEDULE"] || Rails.root.join("config", "recurring.yml")
      yaml_content = File.read(recurring_config_path)

      # Handle YAML aliases by explicitly enabling them
      if Psych::VERSION >= "4.0.0"
        recurring_jobs = YAML.safe_load(yaml_content, aliases: true)[Rails.env]
      else
        recurring_jobs = YAML.load(yaml_content)[Rails.env]
      end

      Rails.logger.info "Running all recurring jobs on startup..."

      # Run all jobs from recurring.yml
      if recurring_jobs
        recurring_jobs.each do |job_name, config|
          job_class = config["class"].constantize
          args = config["args"] || []

          # Enqueue the job
          if args.is_a?(Array)
            job_class.perform_later(*args)
          else
            job_class.perform_later(args)
          end

          Rails.logger.info "Enqueued #{job_class} from recurring jobs config"
        end
      end
    rescue => e
      Rails.logger.error "Error running recurring jobs on startup: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end
end
