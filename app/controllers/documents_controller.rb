class DocumentsController < ApplicationController
  include Pagination

  def index
    document_states = Current.user.document_states
      .where(status: :inbox)
      .order(read: :asc)
      .order(updated_at: :desc)
      .preload(:document)
      .then(&paginate)

    unread_states = document_states.select { |ds| ds.read == false }
    read_states = document_states.select { |ds| ds.read == true }

    @unread_documents = unread_states.map(&:document)
    @read_documents = read_states.map(&:document)

    documents = document_states.map(&:document).map(&:with_view_preferences)
    respond_with_pagination(:index, documents, :append)
  end

  def later
    document_states = Current.user.document_states
      .where(status: :later)
      .order(updated_at: :desc)
      .preload(:document)
      .then(&paginate)

    @documents = document_states.map(&:document).map(&:with_view_preferences)
    respond_with_pagination(:later, @documents, :append)
  end

  def archive
    document_states = Current.user.document_states
      .where(status: :archive)
      .order(updated_at: :desc)
      .preload(:document)
      .then(&paginate)

    @documents = document_states.map(&:document).map(&:with_view_preferences)
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
    respond_with_pagination(:feed, @documents)
  end

  def search
    document_ids = Document.search(params[:q], {
      page: page,
      filter_by: params[:filter],
      per_page: per_page
    })

    @documents = Document.where(id: document_ids).map(&:with_view_preferences)
    respond_with_pagination(:search, @documents)
  end

  def show
    document = Document.find(params[:id])

    unless document.authorized?
      return redirect_to root_path, alert: "Document not found"
    end

    @document = document.with_view_preferences
  end
end
