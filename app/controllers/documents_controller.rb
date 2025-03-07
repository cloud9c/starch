class DocumentsController < ApplicationController
  def index
    if params[:status].nil?
      redirect_to documents_path(status: "inbox")
      return
    end

    case params[:status]
    when "inbox"
      @documents = @documents = Document.visible_to_user_with_status(:inbox).with_channel_details
    when "later"
      @documents = @documents = Document.visible_to_user_with_status(:later).with_channel_details
    when "archive"
      @documents = @documents = Document.visible_to_user_with_status(:archive).with_channel_details
    end
  end

  def destroy
    @document = Document.visible_to_user.find(params[:id])
    document_user_state = @document.document_states.find_by!(user_id: Current.user.id)

    head :unprocessable_entity unless document_user_state.destroy!
  end

  def show
    @document = Document.visible_to_user.with_channel_details.find(params[:id])

    document_user_state = DocumentState.find_by(
      user_id: Current.user.id,
      document_id: @document.id
    )

    document_user_state.update(read: true) if document_user_state.present?
  end

  private
end
