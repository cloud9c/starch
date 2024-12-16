class Page < ApplicationRecord
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  belongs_to :channel

  validates :channel, presence: true
  validates :link, presence: true

  settings index: { number_of_shards: 1 } do
    mappings dynamic: "false" do
      indexes :description, type: "text"
      indexes :link, type: "keyword"
      indexes :published_at, type: "date"
    end
  end

  def as_indexed_json(options = {})
    {
      description: description,
      link: link,
      published_at: published_at
    }
  end
end
