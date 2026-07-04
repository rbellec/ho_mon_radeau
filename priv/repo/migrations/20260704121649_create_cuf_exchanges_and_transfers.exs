defmodule HoMonRadeau.Repo.Migrations.CreateCufExchangesAndTransfers do
  use Ecto.Migration

  def change do
    create table(:cuf_exchanges) do
      add :crew_id, references(:crews, on_delete: :delete_all), null: false
      add :kind, :string, null: false
      add :quantity, :integer, default: 1, null: false
      add :status, :string, default: "open", null: false
      add :note, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:cuf_exchanges, [:crew_id],
             where: "status = 'open'",
             name: :cuf_exchanges_open_unique
           )

    create index(:cuf_exchanges, [:status])

    create table(:cuf_transfers) do
      add :from_crew_id, references(:crews, on_delete: :restrict), null: false
      add :to_crew_id, references(:crews, on_delete: :restrict), null: false
      add :quantity, :integer, null: false
      add :performed_by_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:cuf_transfers, [:from_crew_id])
    create index(:cuf_transfers, [:to_crew_id])
  end
end
