class Upload < ApplicationRecord
  has_many :documents, as: :source, dependent: :destroy
  has_one_attached :content
end
