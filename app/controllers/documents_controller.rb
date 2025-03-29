class DocumentsController < ApplicationController
  include CacheableOffline

  def index
    status = params[:status] ||= "inbox"
    page = params[:page] ? params[:page].to_i : 1
    per_page = 10

    documents_with_read = Document.joins(:document_states)
                            .without_content
                            .select('document_states.read')
                            .where(document_states: { user: Current.user.id, status: status.to_sym })
                            .order('document_states.read' => :desc, 'documents.published_at' => :desc)
                            .limit(per_page)
                            .offset((page - 1) * per_page)

    documents = documents_with_read.map do |doc|
      doc.with_view_preferences
      doc.with_description
      doc
    end

    @unread_documents = documents.select { |doc| doc.read == 0 }
    @read_documents = documents.select { |doc| doc.read == 1 }

    respond_to do |format|
      format.html
      format.turbo_stream do
        if documents.empty?
          head :no_content
        else
          render :index
        end
      end
    end
  end

  def show
    document_state = DocumentState.find_by!(document: params[:id], user: Current.user.id)
    document_state.update(read: true)

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
end
