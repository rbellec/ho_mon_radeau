defmodule HoMonRadeau.Events.Edition do
  @moduledoc """
  Schema for event editions.
  Each edition represents a year of the Tutto Blu event.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "editions" do
    field :year, :integer
    field :name, :string
    field :is_current, :boolean, default: false
    field :start_date, :date
    field :end_date, :date

    # Registration form settings
    field :registration_deadline, :date
    field :participant_form_url, :string
    field :captain_form_url, :string

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating or updating an edition.
  """
  def changeset(edition, attrs) do
    edition
    |> cast(attrs, [
      :year,
      :name,
      :is_current,
      :start_date,
      :end_date,
      :registration_deadline,
      :participant_form_url,
      :captain_form_url
    ])
    |> validate_required([:year])
    |> validate_number(:year, greater_than: 2000, less_than: 3000)
    |> unique_constraint(:year)
    |> validate_dates()
    |> validate_url(:participant_form_url)
    |> validate_url(:captain_form_url)
  end

  defp validate_dates(changeset) do
    start_date = get_field(changeset, :start_date)
    end_date = get_field(changeset, :end_date)

    if start_date && end_date && Date.compare(start_date, end_date) == :gt do
      add_error(changeset, :end_date, "must be after start date")
    else
      changeset
    end
  end

  defp validate_url(changeset, field) do
    validate_change(changeset, field, fn _, value ->
      case URI.parse(value) do
        %URI{scheme: scheme, host: host} when scheme in ["http", "https"] and is_binary(host) ->
          []

        _ ->
          [{field, "must be a valid URL"}]
      end
    end)
  end
end
