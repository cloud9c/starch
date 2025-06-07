class Document < ApplicationRecord
  include Searchable, Queryable, FromEntry

  belongs_to :source, polymorphic: true
  has_many :document_states, dependent: :destroy
  has_many :users, through: :document_states

  validates :content, length: { maximum: 100_000 }

  PER_PAGE = 10

  def extracted_data
    return {} unless url

    cache_key = "#{cache_key_with_version}/extracted_data"
    result = Rails.cache.fetch(cache_key, expires_in: 7.day) do
      EntryUtils.get_extracted_entry_data(url)
    end

    result
  end
end
