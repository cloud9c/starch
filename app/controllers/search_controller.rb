class SearchController < ApplicationController
  allow_unauthenticated_access

  def index
    @query = params[:q]
    if @query.present?
      @results = search_pages
    else
      @results = []
    end
  end

  private

  def search_pages
    Page.search({
      query: {
        bool: {
          must: [
            {
              multi_match: {
                query: @query,
                fields: [ "title^3", "description^2", "content" ],
                fuzziness: "AUTO"
              }
            }
          ],
          filter: build_filters
        }
      },
      sort: [
        { published_at: { order: "desc" } },
        "_score"
      ],
      highlight: {
        fields: {
          title: {},
          description: {},
          content: { fragment_size: 150, number_of_fragments: 3 }
        }
      }
    }).records
  end

  def build_filters
    filters = []

    # Add date filter if provided
    if params[:start_date].present?
      filters << {
        range: {
          published_at: {
            gte: params[:start_date],
            lte: params[:end_date].presence || "now"
          }
        }
      }
    end

    filters
  end
end
