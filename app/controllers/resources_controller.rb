class ResourcesController < ApplicationController
  def serve_file
    resource = Resource.find(params[:id])
    file_path = params[:path]

    # Use blob ID for better cache key
    blob_id = resource.file.blob.id

    # Track access frequency by blob + path
    access_key = "blob/#{blob_id}/#{file_path}/access"
    access_count = Rails.cache.increment(access_key, 1, expires_in: 1.day) || 1

    cache_duration = cache_duration(access_count)

    # Cache by blob ID + file path
    cache_key = "blob/#{blob_id}/#{file_path}/content"
    content = Rails.cache.fetch(cache_key, expires_in: cache_duration) do
      resource.serve_file(file_path)
    end

    return head :not_found unless content

    content_type = Rack::Mime.mime_type(File.extname(file_path))
    expires_in cache_duration, public: true

    send_data content, type: content_type, disposition: "inline"
  end

  private
    def cache_duration(access_count)
      case access_count
      when 0..2 then 30.minutes
      when 3..10 then 2.hours
      when 11..50 then 6.hours
      else 1.day
      end
    end
end
