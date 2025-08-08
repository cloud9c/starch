class DocumentsController < ApplicationController
  include Pagination

  def index
    documents = Document.accessible
      .inbox
      .order(read: :asc)
      .order(created_at: :desc)
      .then(&paginate)

    @unread_documents = documents.select { |doc| doc.read == false }
    @read_documents = documents.select { |doc| doc.read == true }

    documents_with_preferences = documents.map(&:with_view_preferences)
    respond_with_pagination(:index, documents_with_preferences, :append)
  end

  def later
    @documents = Document.accessible
      .later
      .order(updated_at: :desc)
      .then(&paginate)
      .map(&:with_view_preferences)

    respond_with_pagination(:later, @documents, :append)
  end

  def trash
    @documents = Document.accessible
      .trash
      .order(updated_at: :desc)
      .then(&paginate)
      .map(&:with_view_preferences)

    respond_with_pagination(:trash, @documents, :append)
  end

  def feed
    if params[:subscription]
      documents = Subscription.accessible
        .find(params[:subscription])
        .documents
    else
      documents = Document.accessible.feed
    end

    @documents = documents
      .order(published_at: :desc)
      .then(&paginate)
      .map(&:with_view_preferences)

    @subscriptions = Current.user.subscriptions.all
    respond_with_pagination(:feed, @documents, page > 1 ? :append : nil)
  end

  def search
    document_ids = Document.search(params[:q], {
      page: page,
      filter_by: params[:filter],
      per_page: per_page
    })

    @documents = Document.where(id: document_ids).map(&:with_view_preferences)
    respond_with_pagination(:search, @documents,  page > 1 ? :append : nil)
  end

  def show
    @document = Document.accessible.find(params[:id]).with_view_preferences
    @document.update(read: true)

    render :ebook if @document.render_type == :ebook
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Document not found"
  end

  def toolbar
    @document = Document.accessible.find(params[:id]).with_view_preferences
  end

  def read_all
    Document.accessible.where(status: :inbox, read: false).update_all(read: true)
    flash[:notice] = "Marking all as seen"
  end

  def update
    permitted = params.expect(document: [ :status, :progress, :progress_identifier ])

    document = Document.find_by!(id: params[:id], user: Current.user)
    document.update(permitted)

    if permitted[:status] == "trash"
      flash[:notice] = "Document moved to Trash"
    elsif permitted[:status] == "later"
      flash[:notice] = "Document moved to Later"
    elsif permitted[:status] == "inbox"
      flash[:notice] = "Document moved to Inbox"
    else
      head :ok
    end
  end

  def upload
    files = params[:files]

    files.each do |file|
      Current.user.resources.create(
        file: file
      )
    end

    redirect_to inbox_path, notice: "Files uploaded successfully"
  rescue => e
    redirect_to inbox_path, alert: "Upload failed: #{e.message}"
  end
end
