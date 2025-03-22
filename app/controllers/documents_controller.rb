class DocumentsController < ApplicationController
  include CacheableOffline

  def index
    status = params[:status] ||= "inbox"
    page = params[:page].present? ? params[:page].to_i : 1
    per_page = 10

    @documents = Document.owned_by_user(status.to_sym)
                        .select(:id)
                        .order(published_at: :desc)
                        .limit(per_page)
                        .offset((page - 1) * per_page)

    respond_to do |format|
      format.html
      format.turbo_stream do
        if @documents.empty?
          head :no_content
        else
          render :index
        end
      end
    end
  end

  def preview
    @document = Document.owned_by_user
                      .select(:id, :description, :title, :author, :thumbnail_url, :published_at, :entry_id, :url, :updated_at)
                      .find(params[:id])
                      .with_view_preferences

    document_user_state = @document.document_states.find_by(user_id: Current.user.id)
    @seen = document_user_state&.seen || false

    render partial: "preview", locals: { document: @document, seen: @seen }
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

  def seen
    document = Document.find(params[:id])
    document_state = document.document_states.find_by!(user_id: Current.user.id)
    document_state.update(seen: true)
    head :ok
  end
end
