defmodule HoMonRadeau.Events.RegistrationFormNotifierTest do
  use HoMonRadeau.DataCase

  import Swoosh.TestAssertions
  import HoMonRadeau.AccountsFixtures

  alias HoMonRadeau.Events.RegistrationFormNotifier

  defp user_with_nickname(attrs \\ %{}) do
    user = user_fixture(attrs)
    %{user | nickname: "TestNick"}
  end

  defp build_form(rejection_reason) do
    %{rejection_reason: rejection_reason}
  end

  defp build_edition(attrs) do
    %{
      year: Map.get(attrs, :year, 2026),
      registration_deadline: Map.get(attrs, :registration_deadline, nil)
    }
  end

  describe "deliver_form_rejected/2" do
    test "sends rejection email with reason" do
      user = user_with_nickname()
      form = build_form("Photo floue, merci de renvoyer")

      assert {:ok, email} = RegistrationFormNotifier.deliver_form_rejected(user, form)

      assert_email_sent(email)
      assert email.subject == "[Tutto Blu] Fiche d'inscription rejetée"
      assert email.text_body =~ "Photo floue, merci de renvoyer"
      assert email.text_body =~ "TestNick"
    end
  end

  describe "deliver_form_approved/1" do
    test "sends approval email" do
      user = user_with_nickname()

      assert {:ok, email} = RegistrationFormNotifier.deliver_form_approved(user)

      assert_email_sent(email)
      assert email.subject == "[Tutto Blu] Fiche d'inscription validée"
      assert email.text_body =~ "Bonne nouvelle"
      assert email.text_body =~ "TestNick"
    end
  end

  describe "deliver_form_reminder/3" do
    test "sends reminder with deadline" do
      user = user_with_nickname()
      edition = build_edition(%{registration_deadline: ~D[2026-06-01]})

      assert {:ok, email} =
               RegistrationFormNotifier.deliver_form_reminder(user, edition, "Les Flotteurs")

      assert_email_sent(email)
      assert email.subject == "[Tutto Blu] Rappel - Fiche d'inscription"
      assert email.text_body =~ "01/06/2026"
      assert email.text_body =~ "Les Flotteurs"
      assert email.text_body =~ "TestNick"
    end

    test "sends reminder without deadline" do
      user = user_with_nickname()
      edition = build_edition(%{registration_deadline: nil})

      assert {:ok, email} =
               RegistrationFormNotifier.deliver_form_reminder(user, edition, "Les Flotteurs")

      assert_email_sent(email)
      assert email.text_body =~ "dès que possible"
    end
  end

  describe "deliver_form_rejected_to_managers/4" do
    test "sends to managers with raft name" do
      user = user_with_nickname()
      form = build_form("Document manquant")

      manager1 = user_fixture()
      manager2 = user_fixture()
      managers = [%{user: manager1}, %{user: manager2}]

      assert :ok =
               RegistrationFormNotifier.deliver_form_rejected_to_managers(
                 managers,
                 user,
                 form,
                 "Les Flotteurs"
               )

      assert_email_sent(fn email ->
        email.subject == "[Tutto Blu] Fiche rejetée - Les Flotteurs" and
          email.text_body =~ "Document manquant" and
          email.text_body =~ "TestNick"
      end)
    end
  end
end
