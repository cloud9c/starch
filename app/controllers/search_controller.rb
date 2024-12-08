class SearchController < ApplicationController
  allow_unauthenticated_access

  def index
    @query = params[:q]
    
    if @query.present?
      @results = @query
    end
  end
end
