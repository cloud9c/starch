class DocumentsController < ApplicationController
  before_action :load_documents, only: [ :index, :create ]

  def destroy
    @document_user_state = DocumentUserState.find(params[:id])
    render status: :unprocessable_entity unless @document_user_state.destroy!
  end

  private

  def load_documents
    @documents = Document
        .select("documents.*, channels.icon as channel_icon, channels.title as channel_title")
        .left_joins(entry: :channel)
        .order(published_at: :desc)
  end
end
