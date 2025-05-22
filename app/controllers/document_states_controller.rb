class DocumentStatesController < ApplicationController
  def create
    permitted = params.expect(document_state: [ :status, :document_id ])

    DocumentState.create(status: permitted[:status], document_id: permitted[:document_id], user: Current.user)
  end

  def update
    permitted = params.expect(document_state: [ :status, :document_id ])

    document_state = DocumentState.find_by!(document_id: permitted[:document_id], user: Current.user)
    document_state.update(permitted)
  end

  def toolbar
    permitted = params.permit(:document_id)
    @document_state = DocumentState.find_or_create_by(document_id: permitted[:document_id], user: Current.user)

    @document_state.update(read: true)
  end

  def read_all
    DocumentState.where(user: Current.user, status: :inbox, read: false).update_all(read: true)
    flash[:notice] = "Marking all as seen"
  end
end
