defmodule HoMonRadeau.Integration.RaftManagementTest do
  @moduledoc """
  Integration tests for complete raft and crew management workflows.
  """

  use HoMonRadeau.DataCase

  import HoMonRadeau.AccountsFixtures
  import HoMonRadeau.EventsFixtures

  alias HoMonRadeau.Accounts
  alias HoMonRadeau.Events

  # Helper to create a validated user (confirmed + validated by welcome team)
  defp validated_user_fixture(attrs \\ %{}) do
    user = user_fixture(attrs)
    {:ok, user} = Accounts.validate_user(user)
    user
  end

  describe "Raft creation and admin validation" do
    test "full lifecycle: propose, validate, invalidate" do
      # 1. Create a validated user and a current edition
      user = validated_user_fixture()
      edition = edition_fixture(%{is_current: true})

      # 2. User creates a raft with crew
      {:ok, raft} =
        Events.create_raft_with_crew(user, %{name: "Le Radeau Bleu"}, edition.id)

      assert raft.name == "Le Radeau Bleu"
      assert raft.validated == false

      # 3. Verify raft appears as "proposed" in admin list
      proposed = Events.list_admin_rafts(%{"status" => "proposed"})
      assert Enum.any?(proposed, fn %{raft: r} -> r.id == raft.id end)

      validated_list = Events.list_admin_rafts(%{"status" => "validated"})
      refute Enum.any?(validated_list, fn %{raft: r} -> r.id == raft.id end)

      # 4. Admin validates the raft
      admin = validated_user_fixture()
      raft = Events.get_raft!(raft.id)
      {:ok, validated_raft} = Events.validate_raft(raft, admin)
      assert validated_raft.validated == true
      assert validated_raft.validated_by_id == admin.id

      # 5. Verify raft appears as "validated" in admin list
      validated_list = Events.list_admin_rafts(%{"status" => "validated"})
      assert Enum.any?(validated_list, fn %{raft: r} -> r.id == validated_raft.id end)

      proposed = Events.list_admin_rafts(%{"status" => "proposed"})
      refute Enum.any?(proposed, fn %{raft: r} -> r.id == validated_raft.id end)

      # 6. Admin invalidates the raft
      {:ok, invalidated_raft} = Events.invalidate_raft(validated_raft)
      assert invalidated_raft.validated == false
      assert invalidated_raft.validated_at == nil
      assert invalidated_raft.validated_by_id == nil

      # 7. Verify raft is back to "proposed"
      proposed = Events.list_admin_rafts(%{"status" => "proposed"})
      assert Enum.any?(proposed, fn %{raft: r} -> r.id == invalidated_raft.id end)
    end
  end

  describe "Crew role management" do
    test "captain, roles, and manager promotion/demotion" do
      # 1. Create a raft with crew (user A = manager)
      edition = edition_fixture(%{is_current: true})
      user_a = validated_user_fixture(%{email: "user_a@example.com"})

      {:ok, raft} =
        Events.create_raft_with_crew(user_a, %{name: "Role Test Raft"}, edition.id)

      crew = Events.get_crew_by_raft(raft.id)

      # 2. Add members B and C to the crew
      user_b = validated_user_fixture(%{email: "user_b@example.com"})
      user_c = validated_user_fixture(%{email: "user_c@example.com"})

      {:ok, _member_b} = Events.add_crew_member(crew.id, user_b.id)
      {:ok, _member_c} = Events.add_crew_member(crew.id, user_c.id)

      # 3. Set captain on member B
      {:ok, _captain} = Events.set_captain(crew.id, user_b.id)

      # 4. Verify get_captain returns B
      captain = Events.get_captain(crew.id)
      assert captain != nil
      assert captain.user_id == user_b.id

      # 5. Update roles for member B (lead_construction, cooking)
      member_b = Events.get_crew_member(crew.id, user_b.id)
      {:ok, updated_member_b} = Events.update_member_roles(member_b, ["lead_construction", "cooking"])
      assert "lead_construction" in updated_member_b.roles
      assert "cooking" in updated_member_b.roles

      # 6. Verify roles summary reflects the changes
      summary = Events.get_roles_summary(crew.id)
      assert length(summary["lead_construction"]) >= 1
      assert length(summary["cooking"]) >= 1
      assert summary["captain"] != []

      # 7. Promote member C to manager
      {:ok, _promoted} = Events.promote_to_manager(crew.id, user_c.id)

      # 8. Verify both A and C are managers
      managers = Events.get_crew_managers(crew.id)
      manager_ids = Enum.map(managers, & &1.user_id)
      assert user_a.id in manager_ids
      assert user_c.id in manager_ids

      # 9. Demote C from manager
      {:ok, _demoted} = Events.demote_from_manager(crew.id, user_c.id)

      # 10. Verify only A is manager
      managers = Events.get_crew_managers(crew.id)
      manager_ids = Enum.map(managers, & &1.user_id)
      assert user_a.id in manager_ids
      refute user_c.id in manager_ids
    end
  end

  describe "Multiple join requests" do
    test "accepting one request auto-cancels others" do
      edition = edition_fixture(%{is_current: true})

      # 1. Create 2 rafts with different crews
      owner_a = validated_user_fixture(%{email: "owner_a@example.com"})
      owner_b = validated_user_fixture(%{email: "owner_b@example.com"})

      {:ok, raft_a} =
        Events.create_raft_with_crew(owner_a, %{name: "Raft Alpha"}, edition.id)

      {:ok, raft_b} =
        Events.create_raft_with_crew(owner_b, %{name: "Raft Beta"}, edition.id)

      crew_a = Events.get_crew_by_raft(raft_a.id)
      crew_b = Events.get_crew_by_raft(raft_b.id)

      # 2. Create user C who wants to join
      user_c = validated_user_fixture(%{email: "joiner_c@example.com"})

      # 3. User C sends join request to raft A
      {:ok, request_a} = Events.create_join_request(crew_a, user_c, "Want to join A")

      # 4. User C sends join request to raft B
      {:ok, request_b} = Events.create_join_request(crew_b, user_c, "Want to join B")

      assert request_a.status == "pending"
      assert request_b.status == "pending"

      # 5. Raft A accepts user C
      {:ok, %{request: accepted_request}} =
        Events.accept_join_request(request_a, owner_a)

      assert accepted_request.status == "accepted"

      # 6. Verify user C is member of raft A's crew
      member = Events.get_crew_member(crew_a.id, user_c.id)
      assert member != nil
      assert member.user_id == user_c.id

      # 7. Verify user C's request to raft B is automatically cancelled
      updated_request_b = Events.get_join_request!(request_b.id)
      assert updated_request_b.status == "cancelled"
    end
  end

  describe "Raft links management" do
    test "CRUD operations on public and private links" do
      edition = edition_fixture(%{is_current: true})
      user = validated_user_fixture()

      # 1. Create a raft
      {:ok, raft} =
        Events.create_raft_with_crew(user, %{name: "Links Raft"}, edition.id)

      # 2. Add public link and private link
      {:ok, public_link} =
        Events.create_raft_link(%{
          raft_id: raft.id,
          title: "Our Website",
          url: "https://example.com/public",
          is_public: true,
          position: 0
        })

      {:ok, private_link} =
        Events.create_raft_link(%{
          raft_id: raft.id,
          title: "Internal Doc",
          url: "https://example.com/private",
          is_public: false,
          position: 1
        })

      # 3. Verify list_public_raft_links only returns public one
      public_links = Events.list_public_raft_links(raft.id)
      assert length(public_links) == 1
      assert hd(public_links).id == public_link.id

      # 4. Verify list_raft_links returns both
      all_links = Events.list_raft_links(raft.id)
      assert length(all_links) == 2
      all_ids = Enum.map(all_links, & &1.id)
      assert public_link.id in all_ids
      assert private_link.id in all_ids

      # 5. Update a link
      {:ok, updated_link} =
        Events.update_raft_link(public_link, %{title: "Updated Website"})

      assert updated_link.title == "Updated Website"

      # 6. Delete a link
      {:ok, _deleted} = Events.delete_raft_link(private_link)

      # 7. Verify counts
      remaining_links = Events.list_raft_links(raft.id)
      assert length(remaining_links) == 1
      assert hd(remaining_links).id == public_link.id

      public_links = Events.list_public_raft_links(raft.id)
      assert length(public_links) == 1
    end
  end
end
