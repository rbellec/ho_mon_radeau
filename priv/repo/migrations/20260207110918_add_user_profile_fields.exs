defmodule HoMonRadeau.Repo.Migrations.AddUserProfileFields do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :nickname, :string
      add :first_name, :string
      add :last_name, :string
      add :phone_number, :string
      add :profile_picture_url, :string
      add :profile_picture_public, :boolean, default: false, null: false
      add :validated, :boolean, default: false, null: false
    end

    create index(:users, [:nickname])
  end
end
