class DocumentsController < ApplicationController
  include Pagination

  def index
    documents = Current.user.documents
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
    @documents = Current.user.documents
      .later
      .order(updated_at: :desc)
      .then(&paginate)
      .map(&:with_view_preferences)

    respond_with_pagination(:later, @documents, :append)
  end

  def archive
    @documents = Current.user.documents
      .archive
      .order(updated_at: :desc)
      .then(&paginate)
      .map(&:with_view_preferences)

    respond_with_pagination(:archive, @documents, :append)
  end

  def feed
    subscription_id = params[:subscription]
    subscription_condition = subscription_id.present? ?
      { id: subscription_id, user: Current.user } :
      { user: Current.user }

    entry_subquery = Entry.joins(feed: :subscriptions)
                        .where(subscriptions: subscription_condition)
                        .select(:id)

    @documents = Document
      .where(source_type: "Entry", source_id: entry_subquery)
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
    @document = Current.user.documents.find(params[:id]).with_view_preferences
    @document.update(read: true)
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Document not found"
  end

  def toolbar
    @document = Current.user.documents.find(params[:id]).with_view_preferences
  end

  def read_all
    Current.user.documents.where(status: :inbox, read: false).update_all(read: true)
    flash[:notice] = "Marking all as seen"
  end

  def update
    permitted = params.expect(document: [ :status, :progress, :progress_identifier ])

    document = Document.find_by!(id: params[:id], user: Current.user)
    document.update(permitted)
  end

  def upload
    files = params[:files]

    files.each do |file|
      Current.user.resources.create!(
        file: file
      )
    end

    redirect_to inbox_path, notice: "Files uploaded successfully"
  rescue => e
    redirect_to inbox_path, alert: "Upload failed: #{e.message}"
  end
end
