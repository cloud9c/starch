class SearchController < ApplicationController
  def index
    @query = params[:q]
    @results = search_pages if @query.present?
  end

  private

  def search_pages
    results = Document.search(@query, {
      per_page: params[:per_page],
      page: params[:page],
      filter_by: params[:filter]
    })

    document_ids = results["hits"]
      .map { |hit| hit.dig("document", "document_id") }
      .compact
      .uniq

    Document.with_channel_icon.where(id: document_ids)
  end
end
