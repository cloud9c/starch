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
      filter_by: params[:filter],
      user_id: current_user.id
    })

    puts results

    document_ids = results["hits"].map { |hit| hit["document"][:document_id] }.uniq
    documents = Document.where(id: document_ids).index_by(&:document_id)

    results["hits"].each do |hit|
      channel = documents[hit["document"]["channel_id"]]
      hit["document"]["icon"] = channel&.icon
    end

    results
  end
end
