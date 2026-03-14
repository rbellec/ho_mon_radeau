defmodule HoMonRadeau.Repo.Migrations.CreateDrumsTables do
  use Ecto.Migration

  def change do
    create table(:drum_settings) do
      add :unit_price, :decimal, precision: 10, scale: 2, null: false, default: 5
      add :rib_iban, :string
      add :rib_bic, :string

      timestamps(type: :utc_datetime)
    end

    create table(:drum_requests) do
      add :crew_id, references(:crews, on_delete: :delete_all), null: false
      add :quantity, :integer, null: false
      add :unit_price, :decimal, precision: 10, scale: 2, null: false
      add :total_amount, :decimal, precision: 10, scale: 2, null: false
      add :status, :string, default: "pending", null: false
      add :note, :text
      add :paid_at, :utc_datetime
      add :validated_by_id, references(:users)

      timestamps(type: :utc_datetime)
    end

    create index(:drum_requests, [:crew_id])
    create index(:drum_requests, [:status])
  end
end
