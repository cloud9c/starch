class SearchController < ApplicationController
  allow_unauthenticated_access

  def index
    @query = params[:q]
    if @query.present?
      @results = Page.search(@query, {
        per_page: params[:per_page],
        page: params[:page],
        filter_by: params[:filter]
      })
    else
      @results = { hits: [] }
    end
  end
end