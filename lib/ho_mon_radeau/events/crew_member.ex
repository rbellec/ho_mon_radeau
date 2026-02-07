defmodule HoMonRadeau.Events.CrewMember do
  @moduledoc """
  Schema for crew members.
  Represents the membership relationship between users and crews.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias HoMonRadeau.Events.Crew
  alias HoMonRadeau.Accounts.User

  @participation_statuses ~w(pending confirmed declined)

  @valid_roles ~w(
    lead_construction
    cooking
    safe_contact
    logistics
    music
    decoration
    other
  )

  schema "crew_members" do
    field :is_manager, :boolean, default: false
    field :is_captain, :boolean, default: false
    field :roles, {:array, :string}, default: []
    field :participation_status, :string, default: "pending"
    field :joined_at, :utc_datetime

    belongs_to :crew, Crew
    belongs_to :user, User
    belongs_to :invited_by, User

    timestamps(type: :utc_datetime)
  end

  @doc """
  Returns the list of valid participation statuses.
  """
  def participation_statuses, do: @participation_statuses

  @doc """
  Returns the list of valid roles.
  """
  def valid_roles, do: @valid_roles

  @doc """
  Changeset for creating a crew member.
  """
  def changeset(crew_member, attrs) do
    crew_member
    |> cast(attrs, [
      :crew_id,
      :user_id,
      :is_manager,
      :is_captain,
      :roles,
      :participation_status,
      :invited_by_id
    ])
    |> validate_required([:crew_id, :user_id])
    |> validate_inclusion(:participation_status, @participation_statuses)
    |> validate_roles()
    |> put_joined_at()
    |> unique_constraint([:crew_id, :user_id])
    |> foreign_key_constraint(:crew_id)
    |> foreign_key_constraint(:user_id)
  end

  @doc """
  Changeset for updating membership (roles, status).
  """
  def update_changeset(crew_member, attrs) do
    crew_member
    |> cast(attrs, [:is_manager, :is_captain, :roles, :participation_status])
    |> validate_inclusion(:participation_status, @participation_statuses)
    |> validate_roles()
  end

  @doc """
  Changeset for promoting to manager.
  """
  def promote_to_manager_changeset(crew_member) do
    change(crew_member, is_manager: true)
  end

  @doc """
  Changeset for demoting from manager.
  """
  def demote_from_manager_changeset(crew_member) do
    change(crew_member, is_manager: false)
  end

  @doc """
  Changeset for setting captain.
  """
  def set_captain_changeset(crew_member, is_captain) do
    change(crew_member, is_captain: is_captain)
  end

  defp validate_roles(changeset) do
    validate_change(changeset, :roles, fn :roles, roles ->
      invalid_roles = Enum.reject(roles, &(&1 in @valid_roles))

      if Enum.empty?(invalid_roles) do
        []
      else
        [{:roles, "contains invalid roles: #{Enum.join(invalid_roles, ", ")}"}]
      end
    end)
  end

  defp put_joined_at(changeset) do
    if get_change(changeset, :crew_id) && is_nil(get_field(changeset, :joined_at)) do
      put_change(changeset, :joined_at, DateTime.utc_now(:second))
    else
      changeset
    end
  end
end
