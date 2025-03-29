class SearchController < ApplicationController
  def index
    @query = params[:q]
    @documents = search_pages if @query.present?
  end

  private

  def search_pages
    documents = Document.search(@query, {
      per_page: params[:per_page],
      page: params[:page],
      filter_by: params[:filter]
    })

    document_ids = documents["hits"]
      .map { |hit| hit.dig("document", "id") }
      .compact
      .uniq

    documents = Document.where(id: document_ids)
    documents.map(&:with_view_preferences)
  end
end
