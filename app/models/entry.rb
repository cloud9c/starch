class Entry < ApplicationRecord
  has_one :document, dependent: :destroy
  belongs_to :channel

  validates :stable_id, presence: true, uniqueness: true
  validates :fingerprint, presence: true
  validates :channel, presence: true

  attr_accessor :syndicate
  after_save :initialize_document

  scope :recent, -> {
    includes(:document)
      .order("documents.published_at DESC, documents.created_at DESC")
      .limit(5)
  }

  def initialize_document
    document = create_document!(
      title: self.title,
      description: self.description,
      author: self.author,
      published_at: self.published_at,
      url: self.url,
      content: self.content,
    )

    if syndicate
      channel.users.each do |user|
        DocumentUserState.create!(
          user: user,
          document: document
        )
      end
    end
  end
end
