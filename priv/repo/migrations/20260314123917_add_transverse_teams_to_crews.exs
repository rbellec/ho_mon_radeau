defmodule HoMonRadeau.Repo.Migrations.AddTransverseTeamsToCrews do
  use Ecto.Migration

  def change do
    alter table(:crews) do
      add :is_transverse, :boolean, default: false, null: false
      add :transverse_type, :string
      add :name, :string
      add :description, :text
    end

    # Make raft_id nullable for transverse teams
    execute "ALTER TABLE crews ALTER COLUMN raft_id DROP NOT NULL",
            "ALTER TABLE crews ALTER COLUMN raft_id SET NOT NULL"

    # Make edition_id nullable for transverse teams
    execute "ALTER TABLE crews ALTER COLUMN edition_id DROP NOT NULL",
            "ALTER TABLE crews ALTER COLUMN edition_id SET NOT NULL"

    create index(:crews, [:is_transverse])
    create index(:crews, [:transverse_type])
  end
end
