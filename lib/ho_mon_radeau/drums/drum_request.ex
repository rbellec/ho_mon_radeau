defmodule HoMonRadeau.Drums.DrumRequest do
  use Ecto.Schema
  import Ecto.Changeset

  alias HoMonRadeau.Events.Crew
  alias HoMonRadeau.Accounts.User

  @statuses ~w(pending paid)

  schema "drum_requests" do
    field :quantity, :integer
    field :unit_price, :decimal
    field :total_amount, :decimal
    field :status, :string, default: "pending"
    field :note, :string
    field :paid_at, :utc_datetime

    belongs_to :crew, Crew
    belongs_to :validated_by, User

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  def changeset(request, attrs, unit_price) do
    request
    |> cast(attrs, [:quantity, :note])
    |> validate_required([:quantity])
    |> validate_number(:quantity, greater_than_or_equal_to: 0)
    |> calculate_amounts(unit_price)
  end

  defp calculate_amounts(changeset, unit_price) do
    case get_field(changeset, :quantity) do
      nil ->
        changeset

      quantity ->
        total = Decimal.mult(Decimal.new(quantity), unit_price)

        changeset
        |> put_change(:unit_price, unit_price)
        |> put_change(:total_amount, total)
    end
  end

  def payment_changeset(request, validated_by_id) do
    change(request,
      status: "paid",
      paid_at: DateTime.utc_now(:second),
      validated_by_id: validated_by_id
    )
  end
end
