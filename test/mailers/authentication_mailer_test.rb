require "test_helper"

class AuthenticationMailerTest < ActionMailer::TestCase
  test "login" do
    user = users(:one)  # Create a fixture
    mail = AuthenticationMailer.login_email(user, "test_token")
    assert_equal "Log in to Starch", mail.subject
    assert_equal [ user.email_address ], mail.to
  end
end
