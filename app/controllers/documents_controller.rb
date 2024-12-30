class DocumentsController < ApplicationController
  before_action :load_documents, only: [ :index, :create ]

  def destroy
    @document = Document.find(params[:id])
    render status: :unprocessable_entity unless @document.destroy!
  end

  private

  def load_documents
    @documents = current_user.documents.order(published_at: :desc)
  end
end
