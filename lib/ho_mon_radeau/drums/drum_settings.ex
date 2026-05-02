defmodule HoMonRadeau.Drums.DrumSettings do
  use Ecto.Schema
  import Ecto.Changeset

  schema "drum_settings" do
    field :forfait_price, :decimal
    field :rib_iban, :string
    field :rib_bic, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(settings, attrs) do
    settings
    |> cast(attrs, [:forfait_price, :rib_iban, :rib_bic])
    |> validate_number(:forfait_price, greater_than: Decimal.new(0))
  end
end
