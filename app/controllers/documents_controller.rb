class DocumentsController < ApplicationController
  include CacheableOffline

  def index
    status = params[:status] ||= "inbox"
    page = params[:page] ? params[:page].to_i : 1
    per_page = 10

    queried_documents = Document.joins(:document_states)
                                 .joins(entry: { channel: :subscriptions })
                                 .includes(entry: :channel)
                                 .where(document_states: { user: Current.user.id, status: status.to_sym })
                                 .where(subscriptions: { user_id: Current.user.id })
                                 .order("document_states.read" => :asc, "documents.published_at" => :desc)
                                 .limit(per_page)
                                 .offset((page - 1) * per_page)
                                 .select("document_states.read, documents.*, subscriptions.view_extracted")

    documents = queried_documents
    .map do |doc|
      doc.with_view_preferences
      doc.with_description
      doc
    end

    @unread_documents = documents.select { |doc| doc.read == 0 }
    @read_documents = documents.select { |doc| doc.read == 1 }

    respond_to do |format|
      format.html do
        render :index, status: documents.length == per_page ? :ok : :partial_content
      end
      format.turbo_stream do
        if documents.empty?
          head :no_content
        else
          render :index, status: documents.length == per_page ? :ok : :partial_content
        end
      end
    end
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
end
