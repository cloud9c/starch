class Tag < ApplicationRecord
  include UserOwnable

  has_many :subscriptions_tags, dependent: :destroy
  has_many :subscriptions, through: :subscriptions_tags
  has_many :channels, through: :subscriptions
end
