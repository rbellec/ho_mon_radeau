defmodule HoMonRadeau.Repo.Migrations.RefactorDrumsTables do
  use Ecto.Migration

  def up do
    # Drop old tables (clean slate)
    drop_if_exists table(:drum_requests)

    # Add forfait_price to drum_settings (replaces per-request unit_price)
    alter table(:drum_settings) do
      add :forfait_price, :decimal, precision: 10, scale: 2, default: 5
    end

    # Drum types: name, buoyancy, dimensions, price
    create table(:drum_types) do
      add :name, :string, null: false
      add :unit_price, :decimal, precision: 10, scale: 2
      add :buoyancy_kg, :integer
      add :description, :text
      add :position, :integer, default: 0, null: false
      add :active, :boolean, default: true, null: false

      timestamps(type: :utc_datetime)
    end

    # One declaration per crew (upsert pattern)
    create table(:drum_declarations) do
      add :crew_id, references(:crews, on_delete: :delete_all), null: false
      add :declared, :boolean, default: false, null: false
      add :declared_at, :utc_datetime
      add :mode, :string, default: "simple", null: false
      add :total_quantity, :integer
      add :notes, :text
      add :status, :string, default: "pending", null: false
      add :total_amount, :decimal, precision: 10, scale: 2
      add :paid_at, :utc_datetime
      add :validated_by_id, references(:users)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:drum_declarations, [:crew_id])
    create index(:drum_declarations, [:status])

    # One line per (declaration, drum_type)
    create table(:drum_declaration_lines) do
      add :declaration_id, references(:drum_declarations, on_delete: :delete_all), null: false
      add :drum_type_id, references(:drum_types, on_delete: :restrict), null: false
      add :quantity, :integer, default: 0, null: false
      add :unit_price_snapshot, :decimal, precision: 10, scale: 2
      add :subtotal, :decimal, precision: 10, scale: 2

      timestamps(type: :utc_datetime)
    end

    create unique_index(:drum_declaration_lines, [:declaration_id, :drum_type_id])
    create index(:drum_declaration_lines, [:drum_type_id])

    # Seed initial drum types
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    execute("""
    INSERT INTO drum_types (name, buoyancy_kg, description, position, active, unit_price, inserted_at, updated_at)
    VALUES
      ('220L', 67, '1m de haut, capuchon 35cm (38 avec bouchon), ~50cm de diamètre', 1, true, NULL, '#{now}', '#{now}'),
      ('240L', 73, '1,1m de haut, ouverture 38cm (40 avec bouchon), ~50cm de diamètre', 2, true, NULL, '#{now}', '#{now}'),
      ('2026 220L', NULL, 'Bidons 2026 — portance à renseigner par les admins', 3, true, NULL, '#{now}', '#{now}')
    """)
  end

  def down do
    drop_if_exists table(:drum_declaration_lines)
    drop_if_exists table(:drum_declarations)
    drop_if_exists table(:drum_types)

    alter table(:drum_settings) do
      remove :forfait_price
    end

    create table(:drum_requests) do
      add :crew_id, references(:crews, on_delete: :delete_all), null: false
      add :quantity, :integer, null: false
      add :unit_price, :decimal, precision: 10, scale: 2, null: false
      add :total_amount, :decimal, precision: 10, scale: 2, null: false
      add :status, :string, default: "pending", null: false
      add :note, :text
      add :paid_at, :utc_datetime
      add :validated_by_id, references(:users)

      timestamps(type: :utc_datetime)
    end

    create index(:drum_requests, [:crew_id])
    create index(:drum_requests, [:status])
  end
end
