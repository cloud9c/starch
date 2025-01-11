class DocumentUserState < ApplicationRecord
  include UserOwnable

  after_create :update_document_index
  after_destroy :update_document_index

  belongs_to :document
  after_destroy :delete_document_if_no_states

  private

  def delete_document_if_no_states
    document.destroy if document.document_user_states.empty?
  end

  def update_document_index
    document.update_typesense_index
  end
end
