defmodule HoMonRadeau.Repo.Migrations.CreateRaftsAndCrews do
  use Ecto.Migration

  def change do
    # Rafts table - the physical object
    create table(:rafts) do
      add :name, :string, null: false
      add :description, :text
      add :description_short, :string, size: 150
      add :forum_url, :string
      add :picture_url, :string
      add :slug, :string

      # Edition relationship
      add :edition_id, references(:editions, on_delete: :restrict), null: false

      # Validation by admin
      add :validated, :boolean, default: false, null: false
      add :validated_at, :utc_datetime
      add :validated_by_id, references(:users, on_delete: :nilify_all)

      # Link to previous edition's raft with same name (optional)
      add :previous_raft_id, references(:rafts, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    # Raft name must be unique PER EDITION
    create unique_index(:rafts, [:name, :edition_id])
    create unique_index(:rafts, [:slug, :edition_id])
    create index(:rafts, [:edition_id])
    create index(:rafts, [:validated])

    # Crews table - the group of people
    create table(:crews) do
      add :raft_id, references(:rafts, on_delete: :delete_all), null: false
      add :edition_id, references(:editions, on_delete: :restrict), null: false

      timestamps(type: :utc_datetime)
    end

    # One crew per raft (1-1 relationship)
    create unique_index(:crews, [:raft_id])
    create index(:crews, [:edition_id])

    # Crew members table
    create table(:crew_members) do
      add :crew_id, references(:crews, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :is_manager, :boolean, default: false, null: false
      add :is_captain, :boolean, default: false, null: false

      # Multiple roles stored as array
      add :roles, {:array, :string}, default: []

      # Participation status
      add :participation_status, :string, default: "pending"

      # Joined/invited metadata
      add :joined_at, :utc_datetime
      add :invited_by_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    # A user can only be in one crew at a time
    create unique_index(:crew_members, [:crew_id, :user_id])
    create index(:crew_members, [:user_id])
    create index(:crew_members, [:crew_id])

    # Raft public links (external documents, files)
    create table(:raft_links) do
      add :raft_id, references(:rafts, on_delete: :delete_all), null: false
      add :title, :string, null: false
      add :url, :string, null: false
      add :position, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:raft_links, [:raft_id, :position])
  end
end
