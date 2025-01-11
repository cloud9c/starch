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

    document_ids = results["hits"].map { |hit| hit["document"][:document_id] }.uniq
    documents = Document
      .select("documents.*, channels.icon as channel_icon")
      .left_joins(entry: :channel)
      .where(id: document_ids)

    documents
  end
end
