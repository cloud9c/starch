require "test_helper"

class AuthenticationMailerTest < ActionMailer::TestCase
  test "login" do
    user = users(:one)
    travel_to Time.zone.local(2024, 1, 1, 12, 0, 0) do
      mail = AuthenticationMailer.login_email(user, "test_token", 123123)
      assert_equal "Secure link to log in to Starch | 2024-01-01 12:00:00", mail.subject
      assert_equal [ user.email_address ], mail.to
    end
  end
end
