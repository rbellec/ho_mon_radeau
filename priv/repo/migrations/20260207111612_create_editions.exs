defmodule HoMonRadeau.Repo.Migrations.CreateEditions do
  use Ecto.Migration

  def change do
    create table(:editions) do
      add :year, :integer, null: false
      add :name, :string
      add :is_current, :boolean, default: false, null: false
      add :start_date, :date
      add :end_date, :date

      timestamps(type: :utc_datetime)
    end

    create unique_index(:editions, [:year])
  end
end
