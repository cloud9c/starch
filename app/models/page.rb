class Page < ApplicationRecord
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks
  belongs_to :channel
  validates :channel, presence: true
  validates :link, presence: true, uniqueness: true

  settings index: { number_of_shards: 1 } do
    mappings dynamic: "false" do
      indexes :description, type: "text"
      indexes :link, type: "keyword"
      indexes :published_at, type: "date"
      indexes :content, type: "text", analyzer: "standard" do
        indexes :keyword, type: "keyword", ignore_above: 256
      end
      indexes :title, type: "text"  # Added since you're using it in as_indexed_json
    end
  end

  def as_indexed_json(options = {})
    {
      title: title,
      description: description,
      link: link,
      published_at: published_at,
      content: content
    }
  end
end
