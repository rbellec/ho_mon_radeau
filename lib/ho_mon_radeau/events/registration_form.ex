defmodule HoMonRadeau.Events.RegistrationForm do
  @moduledoc """
  Schema for registration forms.
  Stores uploaded registration documents for participants and captains.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias HoMonRadeau.Events.Edition
  alias HoMonRadeau.Accounts.User

  @form_types ~w(participant captain)
  @statuses ~w(pending approved rejected)

  schema "registration_forms" do
    field :form_type, :string
    field :file_key, :string
    field :file_name, :string
    field :file_size, :integer
    field :content_type, :string
    field :status, :string, default: "pending"
    field :rejection_reason, :string
    field :reviewed_at, :utc_datetime
    field :uploaded_at, :utc_datetime

    belongs_to :user, User
    belongs_to :edition, Edition
    belongs_to :reviewed_by, User

    timestamps(type: :utc_datetime)
  end

  @doc """
  Returns the list of valid form types.
  """
  def form_types, do: @form_types

  @doc """
  Returns the list of valid statuses.
  """
  def statuses, do: @statuses

  @doc """
  Changeset for creating a registration form upload.
  """
  def changeset(registration_form, attrs) do
    registration_form
    |> cast(attrs, [
      :user_id,
      :edition_id,
      :form_type,
      :file_key,
      :file_name,
      :file_size,
      :content_type
    ])
    |> validate_required([:user_id, :edition_id, :form_type, :file_key, :file_name])
    |> validate_inclusion(:form_type, @form_types)
    |> validate_file_size()
    |> validate_content_type()
    |> put_uploaded_at()
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:edition_id)
  end

  @doc """
  Changeset for approving a registration form.
  """
  def approve_changeset(registration_form, reviewer_id) do
    registration_form
    |> change(%{
      status: "approved",
      reviewed_at: DateTime.utc_now(:second),
      reviewed_by_id: reviewer_id,
      rejection_reason: nil
    })
  end

  @doc """
  Changeset for rejecting a registration form.
  """
  def reject_changeset(registration_form, reviewer_id, reason) do
    registration_form
    |> change(%{
      status: "rejected",
      reviewed_at: DateTime.utc_now(:second),
      reviewed_by_id: reviewer_id
    })
    |> put_change(:rejection_reason, reason)
    |> validate_required([:rejection_reason])
  end

  # Max file size: 10 MB
  @max_file_size 10 * 1024 * 1024

  defp validate_file_size(changeset) do
    validate_change(changeset, :file_size, fn :file_size, size ->
      if size && size > @max_file_size do
        [{:file_size, "must be less than 10 MB"}]
      else
        []
      end
    end)
  end

  @allowed_content_types ~w(
    application/pdf
    image/jpeg
    image/png
    image/gif
    image/webp
  )

  defp validate_content_type(changeset) do
    validate_change(changeset, :content_type, fn :content_type, type ->
      if type && type not in @allowed_content_types do
        [{:content_type, "must be a PDF or image file"}]
      else
        []
      end
    end)
  end

  defp put_uploaded_at(changeset) do
    if get_change(changeset, :file_key) && is_nil(get_field(changeset, :uploaded_at)) do
      put_change(changeset, :uploaded_at, DateTime.utc_now(:second))
    else
      changeset
    end
  end
end
