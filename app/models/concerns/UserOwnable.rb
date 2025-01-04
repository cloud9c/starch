module UserOwnable
  extend ActiveSupport::Concern

  included do
    belongs_to :user
    attr_readonly :user_id
    default_scope { where(user: Current.user_or_raise!) }
  end
end