defmodule HoMonRadeau.Repo.Migrations.AddCapacityAndApplicationsToRafts do
  use Ecto.Migration

  def change do
    alter table(:rafts) do
      add :max_capacity, :integer, null: true
      add :open_for_applications, :boolean, default: false, null: false
    end
  end
end
