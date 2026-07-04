defmodule HoMonRadeau.CUF.Transfer do
  @moduledoc """
  Schema for a recorded CUF hand-off between two crews. Performed
  unilaterally by the giving crew once an arrangement has been made
  off-app (forum, etc.) - this is the record of it, not a request that
  needs approval.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias HoMonRadeau.Events.Crew
  alias HoMonRadeau.Accounts.User

  schema "cuf_transfers" do
    field :quantity, :integer

    belongs_to :from_crew, Crew
    belongs_to :to_crew, Crew
    belongs_to :performed_by, User

    timestamps(type: :utc_datetime)
  end

  def changeset(transfer, attrs) do
    transfer
    |> cast(attrs, [:from_crew_id, :to_crew_id, :quantity, :performed_by_id])
    |> validate_required([:from_crew_id, :to_crew_id, :quantity])
    |> validate_number(:quantity, greater_than: 0)
    |> validate_different_crews()
    |> foreign_key_constraint(:from_crew_id)
    |> foreign_key_constraint(:to_crew_id)
  end

  defp validate_different_crews(changeset) do
    from_id = get_field(changeset, :from_crew_id)
    to_id = get_field(changeset, :to_crew_id)

    if from_id && to_id && from_id == to_id do
      add_error(changeset, :to_crew_id, "must be different from the giving crew")
    else
      changeset
    end
  end
end
