class DocumentsController < ApplicationController
  def index
    permitted = params.permit(:page)
    page = permitted[:page] ? permitted[:page].to_i : 1

    documents = Document.query(Current.user.id, {
      status: :inbox,
      page: page
    })

    @unread_documents = documents.select { |doc| doc[:read] == 0 }
    @read_documents = documents.select { |doc| doc[:read] == 1 }

    respond_with_pagination(:index, documents)
  end

  def later
    permitted = params.permit(:page)
    page = permitted[:page] ? permitted[:page].to_i : 1

    @documents = Document.query(Current.user.id, {
      status: :later,
      page: page
    })

    respond_with_pagination(:later, @documents)
  end

  def archive
    permitted = params.permit(:page)
    page = permitted[:page] ? permitted[:page].to_i : 1

    @documents = Document.query(Current.user.id, {
      status: :archive,
      page: page
    })

    respond_with_pagination(:archive, @documents)
  end

  def feed
    permitted = params.permit(:page, :subscription)
    page = permitted[:page] ? permitted[:page].to_i : 1

    @documents = Document.query(Current.user.id, {
      page: page,
      subscription: permitted[:subscription]
    })

    @subscriptions = Current.user.subscriptions.includes(:channel).all

    respond_to do |format|
      format.html do
        render :feed, status: @documents.length == Document.per_page ? :ok : :partial_content
      end

      format.turbo_stream do
        render page > 1 ? :append : :feed, status: @documents.length == Document.per_page ? :ok : :partial_content
      end
    end
  end

  def search
    permitted = params.permit(:q, :page, :filter)
    query = permitted[:q]
    page = permitted[:page] ? permitted[:page].to_i : 1

    unless query.present?
      @documents = []
      return respond_with_pagination(:search, @documents)
    end

    result = Document.search(query, {
      page: page,
      filter_by: permitted[:filter]
    })

    document_ids = result["hits"]
      .map { |hit| hit.dig("document", "id") }
      .compact
      .uniq

    @documents = Document.query(Current.user.id, {
      page: page,
      ids: document_ids
    })

    respond_to do |format|
      format.html do
        render :search, status: @documents.length == Document.per_page ? :ok : :partial_content
      end

      format.turbo_stream do
        render page > 1 ? :append : :search, status: @documents.length == Document.per_page ? :ok : :partial_content
      end
    end
  end

  def show
    permitted = params.permit(:id)
    @document = Document.find(permitted[:id])

    if @document.channel&.subscriptions.exists?(user: Current.user)
      @document = @document.with_view_preferences
    end
  end

  private

  def respond_with_pagination(view_name, documents)
    respond_to do |format|
      format.html do
        render view_name, status: documents.length == Document.per_page ? :ok : :partial_content
      end

      format.turbo_stream do
        if documents.empty?
          head :no_content
        else
          render :append, status: documents.length == Document.per_page ? :ok : :partial_content
        end
      end
    end
  end
end
