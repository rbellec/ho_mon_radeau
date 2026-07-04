defmodule HoMonRadeau.Repo.Migrations.AddCufReceivedCountToCrews do
  use Ecto.Migration

  def change do
    alter table(:crews) do
      add :cuf_received_count, :integer, default: 0, null: false
    end
  end
end
