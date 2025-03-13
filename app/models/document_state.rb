class DocumentState < ApplicationRecord
  include UserOwnable

  validates :document_id, uniqueness: { scope: :user_id }
  enum :status, [ :inbox, :later, :archive ]

  belongs_to :document
  after_create :on_create
  after_destroy :on_destroy

  private

  def on_create
    document.update_search_index
  end

  def on_destroy
    if document.entry.nil? && document.document_states.empty?
      document.destroy
    end

    document.update_search_index
  end
end
