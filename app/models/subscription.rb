class Subscription < ApplicationRecord
  belongs_to :user
  belongs_to :feed
  has_many :entries, through: :feed
  has_many :documents, through: :entries

  validates :feed_id, presence: true, uniqueness: { scope: :user_id }
  before_destroy :destroy_feed_documents

  def self.accessible
    Current.user.subscriptions
  end

  private
    def destroy_feed_documents
      documents.where(user: user, status: :feed).destroy_all
    end
end
