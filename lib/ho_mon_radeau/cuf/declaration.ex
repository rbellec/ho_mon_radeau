defmodule HoMonRadeau.CUF.Declaration do
  use Ecto.Schema
  import Ecto.Changeset

  alias HoMonRadeau.Events.Crew
  alias HoMonRadeau.Accounts.User

  schema "cuf_declarations" do
    field :participant_count, :integer
    field :unit_price, :decimal
    field :total_amount, :decimal
    field :status, :string, default: "pending"
    field :participant_user_ids, {:array, :integer}, default: []
    field :validated_at, :utc_datetime

    belongs_to :crew, Crew
    belongs_to :validated_by, User

    timestamps(type: :utc_datetime)
  end

  def changeset(declaration, attrs, unit_price) do
    declaration
    |> cast(attrs, [:participant_count, :participant_user_ids])
    |> validate_required([:participant_count])
    |> validate_number(:participant_count, greater_than: 0)
    |> calculate_amounts(unit_price)
  end

  defp calculate_amounts(changeset, unit_price) do
    case get_field(changeset, :participant_count) do
      nil ->
        changeset

      count ->
        total = Decimal.mult(Decimal.new(count), unit_price)

        changeset
        |> put_change(:unit_price, unit_price)
        |> put_change(:total_amount, total)
    end
  end

  def validation_changeset(declaration, validated_by_id) do
    change(declaration,
      status: "validated",
      validated_at: DateTime.utc_now(:second),
      validated_by_id: validated_by_id
    )
  end
end
