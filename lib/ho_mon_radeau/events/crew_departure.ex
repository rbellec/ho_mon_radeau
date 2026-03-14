defmodule HoMonRadeau.Events.CrewDeparture do
  @moduledoc """
  Records a member's departure from a crew for audit purposes.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias HoMonRadeau.Accounts.User
  alias HoMonRadeau.Events.Crew

  schema "crew_departures" do
    belongs_to :user, User
    belongs_to :crew, Crew
    belongs_to :removed_by, User

    field :cuf_status_at_departure, :string, default: "none"
    field :was_captain, :boolean, default: false
    field :was_manager, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  def changeset(departure, attrs) do
    departure
    |> cast(attrs, [
      :user_id,
      :crew_id,
      :removed_by_id,
      :cuf_status_at_departure,
      :was_captain,
      :was_manager
    ])
    |> validate_required([:user_id, :crew_id])
  end
end
