defmodule HoMonRadeau.Integration.RegistrationFormWorkflowTest do
  use HoMonRadeau.DataCase

  import HoMonRadeau.AccountsFixtures
  import HoMonRadeau.EventsFixtures

  alias HoMonRadeau.Events
  alias HoMonRadeau.Events.RegistrationForm
  alias HoMonRadeau.Repo

  describe "participant submits and gets approved" do
    test "full approval workflow from missing to approved" do
      # Setup: edition, raft with crew, participant member
      edition = edition_fixture()
      captain = user_fixture()
      participant = user_fixture()

      raft = raft_with_crew_fixture(%{user: captain, edition: edition})
      crew = Repo.preload(raft, :crew).crew

      crew_member_fixture(%{user: participant, crew: crew})

      # Status is :missing before any form is submitted
      assert Events.registration_form_status(participant, edition.id) == :missing

      # Participant requires :participant form type
      assert Events.required_form_type(participant, edition.id) == :participant

      # Create a registration form for the participant
      form =
        registration_form_fixture(%{
          user: participant,
          edition: edition,
          form_type: "participant"
        })

      # Status is now :pending
      assert Events.registration_form_status(participant, edition.id) == :pending

      # Admin approves the form
      admin = user_fixture()
      {:ok, approved_form} = Events.approve_registration_form(form, admin)

      # Status is now :approved
      assert Events.registration_form_status(participant, edition.id) == :approved

      # get_current_registration_form returns the approved form
      current = Events.get_current_registration_form(participant.id, edition.id)
      assert current.id == approved_form.id
      assert current.status == "approved"
    end
  end

  describe "captain submits, gets rejected, resubmits" do
    test "rejection and resubmission workflow" do
      # Setup: raft with crew, user as captain
      edition = edition_fixture()
      captain = user_fixture()

      raft = raft_with_crew_fixture(%{user: captain, edition: edition})
      crew = Repo.preload(raft, :crew).crew

      # The creator of the raft is a manager but not necessarily captain;
      # set them as captain explicitly
      {:ok, _} = Events.set_captain(crew.id, captain.id)

      # Required form type is :captain
      assert Events.required_form_type(captain, edition.id) == :captain

      # Submit registration form
      form =
        registration_form_fixture(%{
          user: captain,
          edition: edition,
          form_type: "captain"
        })

      assert Events.registration_form_status(captain, edition.id) == :pending

      # Admin rejects with reason
      admin = user_fixture()
      {:ok, rejected_form} = Events.reject_registration_form(form, admin, "Document illisible")

      assert Events.registration_form_status(captain, edition.id) == :rejected
      assert rejected_form.rejection_reason == "Document illisible"

      # Captain resubmits a new form
      # Use a slightly different uploaded_at to ensure ordering
      new_form =
        %RegistrationForm{}
        |> RegistrationForm.changeset(%{
          user_id: captain.id,
          edition_id: edition.id,
          form_type: "captain",
          file_key: "registrations/resubmit_#{System.unique_integer([:positive])}.pdf",
          file_name: "new_registration.pdf",
          file_size: 2048,
          content_type: "application/pdf"
        })
        |> Ecto.Changeset.put_change(
          :uploaded_at,
          DateTime.add(DateTime.utc_now(:second), 1, :second)
        )
        |> Repo.insert!()

      # get_current_registration_form returns the NEW (most recent) form
      current = Events.get_current_registration_form(captain.id, edition.id)
      assert current.id == new_form.id

      # History has 2 forms
      history = Events.list_user_registration_forms(captain.id, edition.id)
      assert length(history) == 2

      # Admin approves the new form
      {:ok, _approved} = Events.approve_registration_form(new_form, admin)

      # Final status is :approved
      assert Events.registration_form_status(captain, edition.id) == :approved
    end
  end

  describe "form type depends on crew role" do
    test "form type changes with crew role and returns nil when removed" do
      edition = edition_fixture()
      user = user_fixture()
      creator = user_fixture()

      # Create raft with crew (creator becomes manager)
      raft = raft_with_crew_fixture(%{user: creator, edition: edition})
      crew = Repo.preload(raft, :crew).crew

      # Add user as regular member
      crew_member_fixture(%{user: user, crew: crew})

      # Regular member -> :participant
      assert Events.required_form_type(user, edition.id) == :participant

      # Set user as captain -> :captain
      {:ok, _} = Events.set_captain(crew.id, user.id)
      assert Events.required_form_type(user, edition.id) == :captain

      # Remove user from crew -> nil
      Events.remove_crew_member(crew.id, user.id)
      assert Events.required_form_type(user, edition.id) == nil
    end
  end

  describe "admin lists and filters forms" do
    test "list_pending_registration_forms and list_registration_forms with status filter" do
      edition = edition_fixture()
      admin = user_fixture()
      creator = user_fixture()

      raft = raft_with_crew_fixture(%{user: creator, edition: edition})
      crew = Repo.preload(raft, :crew).crew

      # Create 3 users with forms in different statuses
      user_pending = user_fixture()
      user_approved = user_fixture()
      user_rejected = user_fixture()

      crew_member_fixture(%{user: user_pending, crew: crew})
      crew_member_fixture(%{user: user_approved, crew: crew})
      crew_member_fixture(%{user: user_rejected, crew: crew})

      form_pending =
        registration_form_fixture(%{user: user_pending, edition: edition})

      form_approved =
        registration_form_fixture(%{user: user_approved, edition: edition})

      form_rejected =
        registration_form_fixture(%{user: user_rejected, edition: edition})

      # Approve and reject the respective forms
      {:ok, _} = Events.approve_registration_form(form_approved, admin)
      {:ok, _} = Events.reject_registration_form(form_rejected, admin, "Bad quality")

      # list_pending_registration_forms returns only the pending one
      pending_forms = Events.list_pending_registration_forms(edition.id)
      assert length(pending_forms) == 1
      assert hd(pending_forms).id == form_pending.id

      # list_registration_forms with status filter
      approved_forms = Events.list_registration_forms(edition.id, status: "approved")
      assert length(approved_forms) == 1
      assert hd(approved_forms).id == form_approved.id

      rejected_forms = Events.list_registration_forms(edition.id, status: "rejected")
      assert length(rejected_forms) == 1
      assert hd(rejected_forms).id == form_rejected.id

      # Without filter, returns all 3
      all_forms = Events.list_registration_forms(edition.id)
      assert length(all_forms) == 3
    end
  end
end
