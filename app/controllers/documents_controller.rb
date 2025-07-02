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

    documents = document_states.map(&:document)
    respond_with_pagination(:index, documents)
  end

  def later
    document_states = Current.user.document_states
      .where(status: :later)
      .order(updated_at: :desc)
      .preload(:document)
      .then(&paginate)

    @documents = document_states.map(&:document)
    respond_with_pagination(:later, @documents)
  end

  def archive
    document_states = Current.user.document_states
      .where(status: :archive)
      .order(updated_at: :desc)
      .preload(:document)
      .then(&paginate)

    @documents = document_states.map(&:document)
    respond_with_pagination(:later, @documents)
  end

  def feed
    subscription_id = params[:subscription]

    subscription_condition = subscription_id.present? ?
      { id: subscription_id, user: Current.user } :
      { user: Current.user }

    entry_ids = Entry.joins(feed: :subscriptions)
                    .where(subscriptions: subscription_condition)
                    .pluck(:id)

    @documents = Document
      .where(source_type: "Entry", source_id: entry_ids)
      .order(published_at: :desc)
      .then(&paginate)

    @subscriptions = Current.user.subscriptions.includes(:feed).all
    respond_with_pagination(:feed, @documents)
  end

  def search
    document_ids = Document.search(params[:q], {
      page: page,
      filter_by: params[:filter],
      per_page: per_page
    })

    @documents = Document.where(id: document_ids)
    respond_with_pagination(:search, @documents)
  end

  def show
    document = Document.find(params[:id])

    unless @document.authorized?
      return redirect_to root_path, alert: "Document not found"
    end

    @document = document.with_view_preferences
  end
end
