defmodule HoMonRadeau.Repo.Migrations.AddIsPublicToRaftLinks do
  use Ecto.Migration

  def change do
    alter table(:raft_links) do
      add :is_public, :boolean, default: true, null: false
    end
  end
end
