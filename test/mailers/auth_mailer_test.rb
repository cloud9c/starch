require "test_helper"

class AuthMailerTest < ActionMailer::TestCase
  test "magic_link" do
    user = users(:one)  # Create a fixture
    mail = AuthMailer.magic_link(user, "test_token")
    assert_equal "Log in to Starch", mail.subject
    assert_equal [ user.email_address ], mail.to
  end
end
