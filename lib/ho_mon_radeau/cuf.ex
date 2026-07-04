defmodule HoMonRadeau.CUF do
  @moduledoc """
  Context for managing CUF (Cotisation Urbaine Flottante) declarations and settings.
  """

  import Ecto.Query

  alias HoMonRadeau.Repo
  alias HoMonRadeau.Events
  alias HoMonRadeau.CUF.{Declaration, CUFSettings, Exchange, Transfer}
  alias HoMonRadeau.Events.{Crew, CrewMember}
  alias HoMonRadeau.Accounts.User

  ## Settings

  def get_settings do
    Repo.one(CUFSettings) || %CUFSettings{unit_price: Decimal.new(50)}
  end

  def get_unit_price do
    get_settings().unit_price
  end

  def update_settings(attrs) do
    settings = Repo.one(CUFSettings) || %CUFSettings{}

    settings
    |> CUFSettings.changeset(attrs)
    |> Repo.insert_or_update()
  end

  def change_settings(settings \\ nil, attrs \\ %{}) do
    (settings || get_settings())
    |> CUFSettings.changeset(attrs)
  end

  ## Declarations

  def create_declaration(crew_id, participant_user_ids) do
    unit_price = get_unit_price()
    count = length(participant_user_ids)

    %Declaration{crew_id: crew_id}
    |> Declaration.changeset(
      %{participant_count: count, participant_user_ids: participant_user_ids},
      unit_price
    )
    |> Repo.insert()
  end

  def get_pending_declaration(crew_id) do
    Declaration
    |> where([d], d.crew_id == ^crew_id and d.status == "pending")
    |> order_by([d], desc: d.inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  def get_crew_declarations(crew_id) do
    Declaration
    |> where([d], d.crew_id == ^crew_id)
    |> order_by([d], desc: d.inserted_at)
    |> Repo.all()
  end

  def validate_declaration(%Declaration{} = declaration, admin_id) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:declaration, Declaration.validation_changeset(declaration, admin_id))
    |> Ecto.Multi.run(:update_members, fn _repo, %{declaration: decl} ->
      # Mark declared participants
      from(cm in CrewMember,
        where: cm.crew_id == ^decl.crew_id and cm.user_id in ^decl.participant_user_ids
      )
      |> Repo.update_all(set: [participation_status: "confirmed"])

      {:ok, :updated}
    end)
    |> Repo.transaction()
  end

  def list_all_declarations(filter_status \\ nil) do
    query =
      from(d in Declaration,
        join: c in assoc(d, :crew),
        join: r in assoc(c, :raft),
        preload: [crew: {c, raft: r}],
        order_by: [asc: d.status, desc: d.inserted_at]
      )

    query =
      case filter_status do
        nil -> query
        "all" -> query
        status -> where(query, [d], d.status == ^status)
      end

    Repo.all(query)
  end

  def get_declaration!(id) do
    Declaration
    |> Repo.get!(id)
    |> Repo.preload(crew: :raft)
  end

  def get_participant_stats do
    validated =
      from(cm in CrewMember, where: cm.participation_status == "confirmed")
      |> Repo.aggregate(:count)

    settings = get_settings()

    %{
      validated: validated,
      limit: settings.total_limit
    }
  end

  def get_crew_cuf_summary(crew_id) do
    declarations = get_crew_declarations(crew_id)
    pending = Enum.find(declarations, &(&1.status == "pending"))

    validated =
      declarations
      |> Enum.filter(&(&1.status == "validated"))

    total_validated =
      Enum.reduce(validated, 0, fn d, acc -> acc + d.participant_count end)

    total_validated_amount =
      Enum.reduce(validated, Decimal.new(0), fn d, acc ->
        Decimal.add(acc, d.total_amount)
      end)

    %{
      declarations: declarations,
      pending: pending,
      total_validated_participants: total_validated,
      total_validated_amount: total_validated_amount
    }
  end

  ## CUF Exchange ("À vot'bon Cuf")

  @doc """
  Returns a crew's CUF status: how many they've received, how many they
  need (crew member count), how many are actually available (received
  minus what's earmarked in an open offer), and the resulting deficit
  (positive = short, negative = surplus, zero = balanced).
  """
  def get_cuf_status(crew_id) do
    received = Repo.get!(Crew, crew_id).cuf_received_count
    needed = Events.count_crew_members(crew_id)
    offered = open_offer_quantity(crew_id)
    available = received - offered

    %{
      received: received,
      needed: needed,
      available: available,
      deficit: needed - available
    }
  end

  defp open_offer_quantity(crew_id) do
    case get_open_exchange_listing(crew_id) do
      %Exchange{kind: "offer", quantity: quantity} -> quantity
      _ -> 0
    end
  end

  @doc """
  Updates a crew's self-reported CUF received count.
  """
  def update_received_count(%Crew{} = crew, count) do
    crew
    |> Crew.cuf_received_changeset(%{cuf_received_count: count})
    |> Repo.update()
  end

  @doc """
  Gets a crew's open exchange listing (request or offer), if any.
  """
  def get_open_exchange_listing(crew_id) do
    Exchange
    |> where([e], e.crew_id == ^crew_id and e.status == "open")
    |> Repo.one()
  end

  @doc """
  Creates or updates the crew's one open exchange listing.
  """
  def upsert_exchange_listing(crew_id, attrs) do
    (get_open_exchange_listing(crew_id) || %Exchange{crew_id: crew_id})
    |> Exchange.changeset(Map.put(attrs, "crew_id", crew_id))
    |> Repo.insert_or_update()
  end

  @doc """
  Cancels an open exchange listing.
  """
  def cancel_exchange_listing(%Exchange{} = exchange) do
    exchange
    |> Exchange.close_changeset("cancelled")
    |> Repo.update()
  end

  @doc """
  Lists open exchange listings for the board, optionally excluding one crew
  (typically the viewer's own).
  """
  def list_open_exchange_listings(edition_id, exclude_crew_id \\ nil) do
    query =
      from(e in Exchange,
        join: c in assoc(e, :crew),
        join: r in assoc(c, :raft),
        where: e.status == "open" and c.edition_id == ^edition_id,
        order_by: [desc: e.inserted_at],
        preload: [crew: {c, raft: r}]
      )

    query =
      if exclude_crew_id do
        where(query, [e], e.crew_id != ^exclude_crew_id)
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Lists other non-transverse crews in an edition, for picking a CUF
  transfer recipient.
  """
  def list_other_crews(edition_id, exclude_crew_id) do
    from(c in Crew,
      join: r in assoc(c, :raft),
      where:
        c.edition_id == ^edition_id and c.is_transverse == false and c.id != ^exclude_crew_id,
      order_by: r.name,
      select: %{id: c.id, raft_name: r.name}
    )
    |> Repo.all()
  end

  @doc """
  Records a CUF transfer between two crews, performed unilaterally by the
  giving crew. Updates both crews' received counts atomically; fails if
  the giving crew doesn't have enough available to give.
  """
  def transfer_cuf(from_crew_id, to_crew_id, quantity, %User{} = performed_by) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:from_crew, fn repo, _ -> {:ok, repo.get!(Crew, from_crew_id)} end)
    |> Ecto.Multi.run(:to_crew, fn repo, _ -> {:ok, repo.get!(Crew, to_crew_id)} end)
    |> Ecto.Multi.insert(:transfer, fn _ ->
      Transfer.changeset(%Transfer{}, %{
        from_crew_id: from_crew_id,
        to_crew_id: to_crew_id,
        quantity: quantity,
        performed_by_id: performed_by.id
      })
    end)
    |> Ecto.Multi.update(:updated_from, fn %{from_crew: from_crew} ->
      Crew.cuf_received_changeset(from_crew, %{
        cuf_received_count: from_crew.cuf_received_count - quantity
      })
    end)
    |> Ecto.Multi.update(:updated_to, fn %{to_crew: to_crew} ->
      Crew.cuf_received_changeset(to_crew, %{
        cuf_received_count: to_crew.cuf_received_count + quantity
      })
    end)
    |> Repo.transaction()
  end

  @doc """
  Lists all transfers involving a crew (given or received), most recent first.
  """
  def list_crew_transfers(crew_id) do
    from(t in Transfer,
      where: t.from_crew_id == ^crew_id or t.to_crew_id == ^crew_id,
      order_by: [desc: t.inserted_at],
      preload: [:performed_by, from_crew: :raft, to_crew: :raft]
    )
    |> Repo.all()
  end
end
