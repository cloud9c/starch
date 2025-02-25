class SubscriptionsTag < ApplicationRecord
  belongs_to :subscription
  belongs_to :tag
end
