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

  def feed
    @documents = Document.query(Current.user.id, {
      page: params[:page] ? params[:page].to_i : 1
    })

    respond_with_pagination(:feed, @documents)
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

  def toolbar
    @document_state = DocumentState.find_or_initialize_by(document_id: params[:id], user: Current.user)
  end

  def show
    document = Document.find(params[:id])

    if document.channel&.subscriptions.exists?(user: Current.user)
      @document = document.with_view_preferences
    end
  end

  def read
    document_state = DocumentState.find_by!(document_id: params[:id], user: Current.user)
    document_state.update(read: true)

    head :ok
  end

  def search
    query = params[:q]
    page = params[:page] ? params[:page].to_i : 1

    unless query.present?
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

  def read_all
    DocumentState.where(user: Current.user, status: :inbox, read: false).update_all(read: true)
    @flash = { notice: "Marking all as seen" }
  end

  def archive_all
    DocumentState.where(user: Current.user, status: :inbox).update_all(status: :archive)
    @flash = { notice: "Archiving all read documents" }
  end

  private

  def fetch_documents(status)
    Document.query(Current.user.id, {
      status: status,
      page: params[:page] ? params[:page].to_i : 1
    })
  end

  def respond_with_pagination(view_name, documents)
    Rails.logger.debug documents.length

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
