class Folder < ApplicationRecord
  belongs_to :user
  has_many :subscriptions
  has_many :channels, through: :subscriptions
end
