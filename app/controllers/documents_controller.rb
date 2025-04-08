class DocumentsController < ApplicationController
  include CacheableOffline

  def index
    documents = Document.query(Current.user.id, {
      status: :inbox,
      page: params[:page] ? params[:page].to_i : 1
    })

    @unread_documents = documents.select { |doc| doc.read == 0 }
    @read_documents = documents.select { |doc| doc.read == 1 }

    respond_with_pagination(:index, documents)
  end

  def later
    @documents = Document.query(Current.user.id, {
      status: :later,
      page: params[:page] ? params[:page].to_i : 1
    })

    respond_with_pagination(:later, @documents)
  end

  def archive
    @documents = Document.query(Current.user.id, {
      status: :archive,
      page: params[:page] ? params[:page].to_i : 1
    })

    respond_with_pagination(:archive, @documents)
  end

  def show
    document_state = DocumentState.find_by!(document: params[:id], user: Current.user.id)
    @document = document_state.document.with_view_preferences

    render :show
  end

  def destroy
    document_state = DocumentState.find_by!(document: params[:id], user: Current.user.id)

    if document_state.destroy
      redirect_to root_path, notice: "Document was successfully deleted."
    else
      head :unprocessable_entity
    end
  end

  def read
    document_state = DocumentState.find_by!(document: params[:id], user: Current.user.id)
    document_state.update(read: true)

    head :ok
  end

  def search
    query = params[:q]
    page = params[:page] ? params[:page].to_i : 1

    unless query
      @documents = []
      return respond_with_pagination(:search, @documents)
    end

    result = Document.search(query, {
      page: page,
      filter_by: params[:filter]
    })

    document_ids = result["hits"]
      .map { |hit| hit.dig("document", "id") }
      .compact
      .uniq

    @documents = Document.query(Current.user.id, {
      page: page,
      ids: document_ids
    })

    respond_with_pagination(:search, @documents)
  end

  private

  def fetch_documents(status)
    Document.query(Current.user.id, {
      status: status,
      page: params[:page] ? params[:page].to_i : 1
    })
  end

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
