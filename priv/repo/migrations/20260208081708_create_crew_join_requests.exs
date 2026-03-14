defmodule HoMonRadeau.Repo.Migrations.CreateCrewJoinRequests do
  use Ecto.Migration

  def change do
    create table(:crew_join_requests) do
      add :crew_id, references(:crews, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :message, :text
      add :status, :string, default: "pending", null: false
      add :responded_by_id, references(:users, on_delete: :nilify_all)
      add :responded_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:crew_join_requests, [:crew_id, :user_id],
             where: "status = 'pending'",
             name: :crew_join_requests_pending_unique
           )

    create index(:crew_join_requests, [:user_id])
    create index(:crew_join_requests, [:status])
  end
end
