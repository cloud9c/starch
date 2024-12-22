class SearchController < ApplicationController
  allow_unauthenticated_access

  def index
    @query = params[:q]
    @results = search_pages if @query.present?
  end

  private

  def search_pages
    Page.search(@query, {
      per_page: params[:per_page],
      page: params[:page],
      filter_by: params[:filter]
    })
  end
end
