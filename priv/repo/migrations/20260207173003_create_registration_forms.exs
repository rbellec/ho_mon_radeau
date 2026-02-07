defmodule HoMonRadeau.Repo.Migrations.CreateRegistrationForms do
  use Ecto.Migration

  def change do
    create table(:registration_forms) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :edition_id, references(:editions, on_delete: :delete_all), null: false
      add :form_type, :string, null: false
      add :file_key, :string, null: false
      add :file_name, :string, null: false
      add :file_size, :integer
      add :content_type, :string
      add :status, :string, null: false, default: "pending"
      add :rejection_reason, :text
      add :reviewed_at, :utc_datetime
      add :reviewed_by_id, references(:users, on_delete: :nilify_all)
      add :uploaded_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:registration_forms, [:user_id])
    create index(:registration_forms, [:edition_id])
    create index(:registration_forms, [:status])
    create index(:registration_forms, [:user_id, :edition_id])
  end
end
