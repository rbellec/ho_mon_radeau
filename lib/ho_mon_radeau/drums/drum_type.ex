defmodule HoMonRadeau.Drums.DrumType do
  use Ecto.Schema
  import Ecto.Changeset

  schema "drum_types" do
    field :name, :string
    field :unit_price, :decimal
    field :buoyancy_kg, :integer
    field :description, :string
    field :position, :integer, default: 0
    field :active, :boolean, default: true

    has_many :declaration_lines, HoMonRadeau.Drums.DrumDeclarationLine

    timestamps(type: :utc_datetime)
  end

  def changeset(type, attrs) do
    type
    |> cast(attrs, [:name, :unit_price, :buoyancy_kg, :description, :position, :active])
    |> validate_required([:name])
    |> validate_number(:unit_price, greater_than: Decimal.new(0))
    |> validate_number(:buoyancy_kg, greater_than: 0)
  end
end
