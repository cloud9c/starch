class Subscription < ApplicationRecord
  include UserOwnable

  belongs_to :channel
  has_many :subscriptions_tags, dependent: :destroy
  has_many :tags, through: :subscriptions_tags

  has_many :entries, through: :channel
  has_many :documents, through: :entries

  validates :channel_id, presence: true, uniqueness: { scope: :user_id }
  after_create :add_recent_entries
  before_save :sync_document_states, if: :view_extracted_changed?

  private

  def add_recent_entries
    source_type = view_extracted ? :rss_extracted : :rss_original

    recent_entries = channel.entries.recent(source_type)

    recent_entries.each do |entry|
      document = entry.documents.find_by!(source_type: source_type)
      DocumentState.create(
        user_id: user_id,
        document: document
      )
    end
  end

  def sync_document_states
    entry_ids = DocumentState.joins(:document)
                        .where(user_id: user_id)
                        .where(documents: { entry_id: channel.entries.pluck(:id) })
                        .pluck("documents.entry_id")
                        .uniq

    preferred_source_type = view_extracted ? :rss_extracted : :rss_original

    preferred_docs = Document.where(entry_id: entry_ids, source_type: preferred_source_type)
    preferred_docs.each do |doc|
      DocumentState.find_or_create_by(user_id: user_id, document_id: doc.id) do |state|
        state.visible = true
      end
    end

    other_source_type = view_extracted ? :rss_original : :rss_extracted
    other_docs = Document.where(entry_id: entry_ids, source_type: other_source_type)

    DocumentState.where(user_id: user_id, document_id: preferred_docs.pluck(:id)).find_each do |state|
      state.update(visible: true) unless state.visible
    end

    DocumentState.where(user_id: user_id, document_id: other_docs.pluck(:id)).find_each do |state|
      state.update(visible: false) if state.visible
    end
  end
end
