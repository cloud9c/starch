require "test_helper"

class AuthenticationMailerTest < ActionMailer::TestCase
  test "login" do
    user = users(:one)
    travel_to Time.zone.local(2024, 1, 1, 12, 0, 0) do
      mail = AuthenticationMailer.login_email
              .with(user: user, magic_link_token: "test_token", verification_code: 123123)
      assert_equal "Log in to Starch (123123)", mail.subject
      assert_equal [ user.email_address ], mail.to
    end
  end
end
