class DocumentsController < ApplicationController
  def index
    if params[:status].nil?
      redirect_to documents_path(status: "INBOX")
      return
    end

    case params[:status]
    when "INBOX"
      @documents = @documents = Document.owned_by_user_with_status("INBOX").with_channel_details
    when "LATER"
      @documents = @documents = Document.owned_by_user_with_status("LATER").with_channel_details
    when "ARCHIVE"
      @documents = @documents = Document.owned_by_user_with_status("ARCHIVE").with_channel_details
    end
  end

  def destroy
    @document = Document.owned_by_user.find(params[:id])
    document_user_state = @document.document_user_states.find_by!(user_id: Current.user.id)

    head :unprocessable_entity unless document_user_state.destroy!
  end

  def show
    @document = Document.owned_by_user.with_channel_details.find(params[:id])

    document_user_state = DocumentUserState.find_by(
      user_id: Current.user.id,
      document_id: @document.id
    )

    document_user_state.update(read: true) if document_user_state.present?
  end

  private
end
