class DocumentState < ApplicationRecord
  include UserOwnable

  validates :document_id, uniqueness: { scope: :user_id }
  enum :status, [ :inbox, :later, :archive ]

  belongs_to :document
  after_destroy :delete_zombie_document

  private

  def delete_zombie_document
    document.destroy if document.entry.nil? && document.document_states.empty?
  end
end
