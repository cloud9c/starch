class Folder < ApplicationRecord
  include UserOwnable

  has_many :subscriptions
  has_many :channels, through: :subscriptions
end
