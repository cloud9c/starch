class SearchController < ApplicationController
  allow_unauthenticated_access

  def index
    @query = params[:q]
    @results = search_pages if @query.present?
  end

  private

  def search_pages
    results = current_user.documents.search(@query, {
      per_page: params[:per_page],
      page: params[:page],
      filter_by: params[:filter]
    })

    channel_ids = results["hits"].map { |hit| hit["document"]["channel_id"] }.uniq

    channels = Channel.where(id: channel_ids).index_by(&:id)

    results["hits"].each do |hit|
      channel = channels[hit["document"]["channel_id"]]
      hit["document"]["icon"] = channel&.icon
    end

    results
  end
end
