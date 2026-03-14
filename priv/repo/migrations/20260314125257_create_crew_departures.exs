defmodule HoMonRadeau.Repo.Migrations.CreateCrewDepartures do
  use Ecto.Migration

  def change do
    create table(:crew_departures) do
      add :user_id, references(:users, on_delete: :nilify_all)
      add :crew_id, references(:crews, on_delete: :nilify_all)
      add :removed_by_id, references(:users, on_delete: :nilify_all)
      add :cuf_status_at_departure, :string, default: "none"
      add :was_captain, :boolean, default: false
      add :was_manager, :boolean, default: false

      timestamps(type: :utc_datetime)
    end

    create index(:crew_departures, [:crew_id])
    create index(:crew_departures, [:user_id])
  end
end
