class EmailSender < ApplicationRecord
  has_many :documents, as: :source, dependent: :destroy
end
