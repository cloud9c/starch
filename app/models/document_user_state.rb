class DocumentUserState < ApplicationRecord
  include UserOwnable

  validates :document_id, uniqueness: { scope: :user_id }
  validates :status, inclusion: { in: %w[INBOX LATER ARCHIVE] }

  after_create :update_document_index
  after_destroy :update_document_index

  belongs_to :document
  after_destroy :delete_zombie_document

  private

  def update_document_index
    document.update_search_index
  end

  def delete_zombie_document
    document.destroy if document.entry.nil? && document.document_user_states.empty?
  end
end
