class DocumentState < ApplicationRecord
  belongs_to :user
  validates :document_id, presence: true, uniqueness: { scope: :user_id }
  validates :status, presence: true
  enum :status, [ :inbox, :later, :archive ]

  belongs_to :document
  after_create :update_document_search_index
  after_commit :cleanup_document, on: :destroy

  private
    def update_document_search_index
      document.update_search_index
    end

    def cleanup_document
      unless document.entry? || document.document_states.exists?
        document.destroy
      else
        document.update_search_index
      end
    end
end
