class DocumentState < ApplicationRecord
  belongs_to :user
  validates :document_id, presence: true, uniqueness: { scope: :user_id }
  validates :status, presence: true
  enum :status, [ :inbox, :later, :archive ]

  belongs_to :document
  after_create :on_create
  after_destroy :on_destroy

  private

  def on_create
    document.update_search_index
  end

  def on_destroy
    unless document.entry? || document.document_states.exists?
      document.destroy
    end

    document.update_search_index
  end
end
