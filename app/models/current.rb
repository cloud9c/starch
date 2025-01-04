class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :direct_user

  class MissingCurrentUser < StandardError; end
  class SessionExists < StandardError; end

  def user_or_raise!
    raise Current::MissingCurrentUser, "You must set a user with Current.user=" unless self.user

    self.user
  end

  def user
    session&.user || direct_user
  end

  def user=(new_user)
    raise Current::SessionExists, "Cannot set user when session exists" if session
    self.direct_user = new_user
  end
end
