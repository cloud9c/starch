class DocumentsController < ApplicationController
  before_action :load_documents, only: [ :index, :create ]

  def create
    @document = Document.new(document_params)
    if @document.save
      respond_to do |format|
        format.turbo_stream
      end
    end
  end

  def destroy
    @document = Document.find(params[:id])
    document_user_state = @document.document_user_states.find_by!(user_id: Current.user.id)

    head :unprocessable_entity unless document_user_state.destroy!
  end

  private

  def load_documents
    @documents = Document.with_channel_details
  end
end
