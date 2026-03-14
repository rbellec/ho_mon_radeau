defmodule HoMonRadeau.Drums do
  @moduledoc """
  Context for managing drum (bidon) requests and settings.
  """

  import Ecto.Query

  alias HoMonRadeau.Repo
  alias HoMonRadeau.Drums.{DrumRequest, DrumSettings}

  ## Settings

  @doc """
  Gets the current drum settings, or returns defaults.
  """
  def get_settings do
    Repo.one(DrumSettings) || %DrumSettings{unit_price: Decimal.new(5)}
  end

  @doc """
  Gets the current unit price per drum.
  """
  def get_unit_price do
    get_settings().unit_price
  end

  @doc """
  Updates drum settings (unit price, RIB).
  """
  def update_settings(attrs) do
    settings = Repo.one(DrumSettings) || %DrumSettings{}

    settings
    |> DrumSettings.changeset(attrs)
    |> Repo.insert_or_update()
  end

  @doc """
  Returns a changeset for drum settings.
  """
  def change_settings(settings \\ nil, attrs \\ %{}) do
    (settings || get_settings())
    |> DrumSettings.changeset(attrs)
  end

  ## Drum Requests

  @doc """
  Creates a drum request for a crew.
  """
  def create_drum_request(crew_id, attrs) do
    unit_price = get_unit_price()

    %DrumRequest{crew_id: crew_id}
    |> DrumRequest.changeset(attrs, unit_price)
    |> Repo.insert()
  end

  @doc """
  Updates a pending drum request.
  """
  def update_drum_request(%DrumRequest{status: "paid"}, _attrs) do
    {:error, :already_paid}
  end

  def update_drum_request(%DrumRequest{} = request, attrs) do
    unit_price = get_unit_price()

    request
    |> DrumRequest.changeset(attrs, unit_price)
    |> Repo.update()
  end

  @doc """
  Validates a drum payment (marks as paid).
  """
  def validate_payment(%DrumRequest{} = request, validated_by_id) do
    request
    |> DrumRequest.payment_changeset(validated_by_id)
    |> Repo.update()
  end

  @doc """
  Gets all drum requests for a crew.
  """
  def get_crew_requests(crew_id) do
    DrumRequest
    |> where([dr], dr.crew_id == ^crew_id)
    |> order_by([dr], desc: dr.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets the pending (active) drum request for a crew.
  """
  def get_pending_request(crew_id) do
    DrumRequest
    |> where([dr], dr.crew_id == ^crew_id and dr.status == "pending")
    |> order_by([dr], desc: dr.inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  Returns a summary of drum requests for a crew.
  """
  def get_crew_summary(crew_id) do
    requests = get_crew_requests(crew_id)

    paid = Enum.filter(requests, &(&1.status == "paid"))
    pending = Enum.filter(requests, &(&1.status == "pending"))

    %{
      total_paid_quantity: Enum.reduce(paid, 0, fn r, acc -> acc + r.quantity end),
      total_paid_amount:
        Enum.reduce(paid, Decimal.new(0), fn r, acc -> Decimal.add(acc, r.total_amount) end),
      pending_quantity: Enum.reduce(pending, 0, fn r, acc -> acc + r.quantity end),
      pending_amount:
        Enum.reduce(pending, Decimal.new(0), fn r, acc -> Decimal.add(acc, r.total_amount) end),
      requests: requests
    }
  end

  @doc """
  Returns a changeset for a drum request.
  """
  def change_drum_request(request \\ %DrumRequest{}, attrs \\ %{}) do
    DrumRequest.changeset(request, attrs, get_unit_price())
  end

  @doc """
  Lists all drum requests for admin view with raft info.
  """
  def list_all_requests(filter_status \\ nil) do
    query =
      from(dr in DrumRequest,
        join: c in assoc(dr, :crew),
        join: r in assoc(c, :raft),
        preload: [crew: {c, raft: r}],
        order_by: [asc: dr.status, desc: dr.inserted_at]
      )

    query =
      case filter_status do
        nil -> query
        "all" -> query
        status -> where(query, [dr], dr.status == ^status)
      end

    Repo.all(query)
  end

  @doc """
  Gets a drum request by ID.
  """
  def get_request!(id) do
    DrumRequest
    |> Repo.get!(id)
    |> Repo.preload(crew: :raft)
  end
end
