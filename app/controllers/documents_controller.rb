class DocumentsController < ApplicationController
  include CacheableOffline

  def index
    status = params[:status] ||= "inbox"
    page = params[:page].present? ? params[:page].to_i : 1
    per_page = 3

    @documents = Document.owned_by_user(status.to_sym)
                        .select(:id)
                        .limit(per_page)
                        .offset((page - 1) * per_page)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def preview
    @document = Document.owned_by_user.find(params[:id]).with_view_preferences
    render partial: "preview", locals: { document: @document }
  end

  def show
    @document = Document.owned_by_user.find(params[:id])
    document_user_state = @document.document_states.find_by(user_id: Current.user.id)
    document_user_state.update(read: true) if document_user_state.present?
    @document = @document.with_view_preferences
  end

  def destroy
    @document = Document.owned_by_user.find(params[:id])
    document_user_state = @document.document_states.find_by!(user_id: Current.user.id)

    if document_user_state.destroy
      redirect_to root_path, notice: "Document was successfully deleted."
    else
      head :unprocessable_entity
    end
  end
end
