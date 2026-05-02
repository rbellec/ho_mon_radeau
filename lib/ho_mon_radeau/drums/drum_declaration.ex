defmodule HoMonRadeau.Drums.DrumDeclaration do
  use Ecto.Schema
  import Ecto.Changeset

  alias HoMonRadeau.Events.Crew
  alias HoMonRadeau.Accounts.User
  alias HoMonRadeau.Drums.DrumDeclarationLine

  @modes ~w(simple specific)
  @statuses ~w(pending paid)

  schema "drum_declarations" do
    field :declared, :boolean, default: false
    field :declared_at, :utc_datetime
    field :mode, :string, default: "simple"
    field :total_quantity, :integer
    field :notes, :string
    field :status, :string, default: "pending"
    field :total_amount, :decimal
    field :paid_at, :utc_datetime

    belongs_to :crew, Crew
    belongs_to :validated_by, User

    has_many :lines, DrumDeclarationLine,
      foreign_key: :declaration_id,
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  def modes, do: @modes
  def statuses, do: @statuses

  def changeset(declaration, attrs) do
    declaration
    |> cast(attrs, [:mode, :total_quantity, :notes])
    |> validate_inclusion(:mode, @modes)
    |> validate_by_mode()
  end

  def declare_changeset(declaration, attrs) do
    declaration
    |> changeset(attrs)
    |> put_change(:declared, true)
    |> put_change(:declared_at, DateTime.utc_now(:second))
  end

  def payment_changeset(declaration, validated_by_id) do
    change(declaration,
      status: "paid",
      paid_at: DateTime.utc_now(:second),
      validated_by_id: validated_by_id
    )
  end

  defp validate_by_mode(changeset) do
    case get_field(changeset, :mode) do
      "simple" ->
        changeset
        |> validate_required([:total_quantity])
        |> validate_number(:total_quantity, greater_than_or_equal_to: 0)

      "specific" ->
        changeset

      _ ->
        changeset
    end
  end
end
