module UserOwnable
  extend ActiveSupport::Concern

  included do
    belongs_to :user
    attr_readonly :user_id
  end
end
