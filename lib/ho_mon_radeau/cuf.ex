defmodule HoMonRadeau.CUF do
  @moduledoc """
  Context for managing CUF (Cotisation Urbaine Flottante) declarations and settings.
  """

  import Ecto.Query

  alias HoMonRadeau.Repo
  alias HoMonRadeau.CUF.{Declaration, CUFSettings}
  alias HoMonRadeau.Events.CrewMember

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
end
