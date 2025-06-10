class Document < ApplicationRecord
  include Searchable, Queryable, FromEntry, Extractable

  belongs_to :source, polymorphic: true
  has_many :document_states, dependent: :destroy
  has_many :users, through: :document_states

  validates :content, length: { maximum: 100_000 }

  PER_PAGE = 10
end
