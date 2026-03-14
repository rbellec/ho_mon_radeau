defmodule HoMonRadeau.DrumsTest do
  use HoMonRadeau.DataCase

  alias HoMonRadeau.Drums
  alias HoMonRadeau.Events

  import HoMonRadeau.AccountsFixtures

  setup do
    user = user_fixture()

    user =
      user
      |> Ecto.Changeset.change(validated: true)
      |> Repo.update!()

    {:ok, edition} = Events.get_or_create_current_edition()

    {:ok, %{crew: crew}} =
      Events.create_raft_with_crew(user, %{name: "Test Raft"}, edition.id)

    %{user: user, crew: crew}
  end

  describe "settings" do
    test "get_settings/0 returns defaults when no settings exist" do
      settings = Drums.get_settings()
      assert Decimal.equal?(settings.unit_price, Decimal.new(5))
    end

    test "update_settings/1 creates or updates settings" do
      assert {:ok, settings} = Drums.update_settings(%{unit_price: "7.50", rib_iban: "FR76123"})
      assert Decimal.equal?(settings.unit_price, Decimal.new("7.50"))
      assert settings.rib_iban == "FR76123"
    end
  end

  describe "drum requests" do
    test "create_drum_request/2 creates a request with calculated amount", %{crew: crew} do
      assert {:ok, request} = Drums.create_drum_request(crew.id, %{quantity: 10})
      assert request.quantity == 10
      assert request.status == "pending"
      assert Decimal.equal?(request.unit_price, Decimal.new(5))
      assert Decimal.equal?(request.total_amount, Decimal.new(50))
    end

    test "update_drum_request/2 updates a pending request", %{crew: crew} do
      {:ok, request} = Drums.create_drum_request(crew.id, %{quantity: 10})
      assert {:ok, updated} = Drums.update_drum_request(request, %{quantity: 20})
      assert updated.quantity == 20
      assert Decimal.equal?(updated.total_amount, Decimal.new(100))
    end

    test "update_drum_request/2 rejects update on paid request", %{crew: crew, user: user} do
      {:ok, request} = Drums.create_drum_request(crew.id, %{quantity: 10})
      {:ok, paid_request} = Drums.validate_payment(request, user.id)
      assert {:error, :already_paid} = Drums.update_drum_request(paid_request, %{quantity: 20})
    end

    test "validate_payment/2 marks request as paid", %{crew: crew, user: user} do
      {:ok, request} = Drums.create_drum_request(crew.id, %{quantity: 10})
      assert {:ok, paid} = Drums.validate_payment(request, user.id)
      assert paid.status == "paid"
      assert paid.paid_at != nil
      assert paid.validated_by_id == user.id
    end

    test "get_crew_summary/1 returns correct totals", %{crew: crew, user: user} do
      {:ok, req1} = Drums.create_drum_request(crew.id, %{quantity: 10})
      {:ok, _} = Drums.validate_payment(req1, user.id)
      {:ok, _req2} = Drums.create_drum_request(crew.id, %{quantity: 5})

      summary = Drums.get_crew_summary(crew.id)
      assert summary.total_paid_quantity == 10
      assert summary.pending_quantity == 5
      assert Decimal.equal?(summary.total_paid_amount, Decimal.new(50))
      assert Decimal.equal?(summary.pending_amount, Decimal.new(25))
    end

    test "get_pending_request/1 returns only the pending request", %{crew: crew, user: user} do
      {:ok, req1} = Drums.create_drum_request(crew.id, %{quantity: 10})
      {:ok, _} = Drums.validate_payment(req1, user.id)
      {:ok, req2} = Drums.create_drum_request(crew.id, %{quantity: 5})

      pending = Drums.get_pending_request(crew.id)
      assert pending.id == req2.id
    end
  end
end
