defmodule HoMonRadeau.Events.CrewJoinRequest do
  @moduledoc """
  Schema for crew join requests.
  Represents a user's request to join a crew.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias HoMonRadeau.Events.Crew
  alias HoMonRadeau.Accounts.User

  @statuses ~w(pending accepted rejected cancelled)

  schema "crew_join_requests" do
    field :message, :string
    field :status, :string, default: "pending"
    field :responded_at, :utc_datetime

    belongs_to :crew, Crew
    belongs_to :user, User
    belongs_to :responded_by, User

    timestamps(type: :utc_datetime)
  end

  @doc """
  Returns the list of valid statuses.
  """
  def statuses, do: @statuses

  @doc """
  Changeset for creating a join request.
  """
  def changeset(join_request, attrs) do
    join_request
    |> cast(attrs, [:crew_id, :user_id, :message])
    |> validate_required([:crew_id, :user_id])
    |> validate_inclusion(:status, @statuses)
    |> foreign_key_constraint(:crew_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:crew_id, :user_id],
      name: :crew_join_requests_pending_unique,
      message: "you already have a pending request for this crew"
    )
  end

  @doc """
  Changeset for responding to a join request (accept/reject).
  """
  def response_changeset(join_request, attrs) do
    join_request
    |> cast(attrs, [:status, :responded_by_id, :responded_at])
    |> validate_required([:status])
    |> validate_inclusion(:status, @statuses)
    |> put_responded_at()
  end

  defp put_responded_at(changeset) do
    if get_change(changeset, :status) in ["accepted", "rejected"] do
      put_change(changeset, :responded_at, DateTime.utc_now(:second))
    else
      changeset
    end
  end
end
