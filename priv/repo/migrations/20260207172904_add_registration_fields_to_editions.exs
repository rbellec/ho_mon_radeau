defmodule HoMonRadeau.Repo.Migrations.AddRegistrationFieldsToEditions do
  use Ecto.Migration

  def change do
    alter table(:editions) do
      add :registration_deadline, :date
      add :participant_form_url, :string
      add :captain_form_url, :string
    end
  end
end
