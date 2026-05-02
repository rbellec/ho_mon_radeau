defmodule HoMonRadeau.Drums.DrumDeclarationLine do
  use Ecto.Schema
  import Ecto.Changeset

  alias HoMonRadeau.Drums.{DrumDeclaration, DrumType}

  schema "drum_declaration_lines" do
    field :quantity, :integer, default: 0
    field :unit_price_snapshot, :decimal
    field :subtotal, :decimal

    belongs_to :declaration, DrumDeclaration
    belongs_to :drum_type, DrumType

    timestamps(type: :utc_datetime)
  end

  def changeset(line, attrs) do
    line
    |> cast(attrs, [:quantity, :drum_type_id, :unit_price_snapshot])
    |> validate_required([:quantity, :drum_type_id])
    |> validate_number(:quantity, greater_than_or_equal_to: 0)
    |> calculate_subtotal()
  end

  defp calculate_subtotal(changeset) do
    quantity = get_field(changeset, :quantity) || 0
    unit_price = get_field(changeset, :unit_price_snapshot)

    if unit_price do
      subtotal = Decimal.mult(Decimal.new(quantity), unit_price)
      put_change(changeset, :subtotal, subtotal)
    else
      put_change(changeset, :subtotal, Decimal.new(0))
    end
  end
end
