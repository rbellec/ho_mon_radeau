defmodule HoMonRadeau.Repo.Migrations.CreateCufTables do
  use Ecto.Migration

  def change do
    create table(:cuf_settings) do
      add :unit_price, :decimal, precision: 10, scale: 2, null: false, default: 50
      add :total_limit, :integer
      add :rib_iban, :string
      add :rib_bic, :string

      timestamps(type: :utc_datetime)
    end

    create table(:cuf_declarations) do
      add :crew_id, references(:crews, on_delete: :delete_all), null: false
      add :participant_count, :integer, null: false
      add :unit_price, :decimal, precision: 10, scale: 2, null: false
      add :total_amount, :decimal, precision: 10, scale: 2, null: false
      add :status, :string, default: "pending", null: false
      add :participant_user_ids, {:array, :integer}, default: []
      add :validated_at, :utc_datetime
      add :validated_by_id, references(:users)

      timestamps(type: :utc_datetime)
    end

    create index(:cuf_declarations, [:crew_id])
    create index(:cuf_declarations, [:status])
  end
end
