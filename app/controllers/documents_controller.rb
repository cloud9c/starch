class DocumentsController < ApplicationController
  include CacheableOffline

  def index
    status = params[:status]

    unless status.present? && DocumentState.statuses.key?(status)
      redirect_to documents_path(status: "inbox")
      return
    end

    @documents = Document.owned_by_user(status.to_sym).with_channel_details
    @documents.map(&:with_view_preferences)
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

  def show
    @document = Document.where(id: params[:id]).owned_by_user.with_channel_details.first!

    document_user_state = @document.document_states.find_by(user_id: Current.user.id)
    document_user_state.update(read: true) if document_user_state.present?

    @document.with_view_preferences
  end
end
