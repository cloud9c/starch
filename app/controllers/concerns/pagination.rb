module Pagination
  extend ActiveSupport::Concern

  DEFAULT_PER_PAGE = 10

  def page
    params[:page]&.to_i || 1
  end

  def per_page
    params[:per_page]&.to_i || DEFAULT_PER_PAGE
  end

  def paginate_offset
    (page-1)*per_page
  end

  def paginate
    ->(it) { it.limit(per_page).offset(paginate_offset) }
  end

  def respond_with_pagination(view_name, elements, turbo_stream_name = nil)
    respond_to do |format|
      format.html do
        render view_name, status: elements.size == per_page ? :ok : :partial_content
      end

      format.turbo_stream do
        if elements.empty?
          head :no_content
        else
          render turbo_stream_name || view_name, status: elements.size == per_page ? :ok : :partial_content
        end
      end
    end
  end
end
