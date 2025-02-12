class DocumentsController < ApplicationController
  before_action :load_documents, only: [ :index ]

  def destroy
    @document = Document.owned_by_user.find(params[:id])
    document_user_state = @document.document_user_states.find_by!(user_id: Current.user.id)

    head :unprocessable_entity unless document_user_state.destroy!
  end

  def show
    @document = Document.owned_by_user.with_channel_details.find(params[:id])
  end

  private

  def load_documents
    @documents = Document.owned_by_user.with_channel_details
  end
end
