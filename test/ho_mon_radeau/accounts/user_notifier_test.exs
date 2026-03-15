defmodule HoMonRadeau.Accounts.UserNotifierTest do
  use HoMonRadeau.DataCase

  import Swoosh.TestAssertions
  import HoMonRadeau.AccountsFixtures

  alias HoMonRadeau.Accounts.UserNotifier

  describe "deliver_update_email_instructions/2" do
    test "sends email with update URL" do
      user = user_fixture()
      url = "https://example.com/users/settings/confirm-email/some-token"

      assert {:ok, email} = UserNotifier.deliver_update_email_instructions(user, url)

      assert_email_sent(email)
      assert email.subject == "Update email instructions"
      assert email.text_body =~ url
      assert email.text_body =~ user.email
    end

    test "uses the correct sender" do
      user = user_fixture()

      assert {:ok, email} =
               UserNotifier.deliver_update_email_instructions(user, "https://example.com")

      assert {"Ho Mon Radeau", _from_email} = email.from
    end
  end

  describe "deliver_login_instructions/2" do
    test "sends confirmation instructions for unconfirmed user" do
      user = unconfirmed_user_fixture()
      url = "https://example.com/users/confirm/some-token"

      assert {:ok, email} = UserNotifier.deliver_login_instructions(user, url)

      assert_email_sent(email)
      assert email.subject == "Confirmation instructions"
      assert email.text_body =~ url
      assert email.text_body =~ "confirm your account"
    end

    test "sends magic link instructions for confirmed user" do
      user = user_fixture()
      url = "https://example.com/users/log-in/some-token"

      assert {:ok, email} = UserNotifier.deliver_login_instructions(user, url)

      assert_email_sent(email)
      assert email.subject == "Log in instructions"
      assert email.text_body =~ url
      assert email.text_body =~ "log into your account"
    end
  end
end
