class DocumentStatesController < ApplicationController
  def create
    permitted = params.permit(:status, :document_id)

    DocumentState.create(status: permitted[:status], document_id: permitted[:document_id], user: Current.user)
  end

  def update
    permitted = params.expect(document_state: [ :status, :document_id ])

    document_state = DocumentState.find_by(document_id: permitted[:document_id], user: Current.user)

    document_state&.update(permitted)
  end
end
