defmodule HoMonRadeau.Accounts.ApiToken do
  @moduledoc """
  Schema for API tokens used to authenticate API requests.
  Each user can have multiple tokens with labels for identification.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias HoMonRadeau.Accounts.User

  schema "api_tokens" do
    field :token_hash, :binary
    field :label, :string
    field :last_used_at, :utc_datetime
    field :revoked_at, :utc_datetime

    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @hash_algorithm :sha256

  @doc """
  Creates a new API token for a user.
  Returns {raw_token, changeset} where raw_token is the plaintext token
  to show to the user once (it's not stored).
  """
  def build_token(user, label) do
    raw_token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
    hashed_token = :crypto.hash(@hash_algorithm, raw_token)

    changeset =
      %__MODULE__{}
      |> change(%{
        user_id: user.id,
        token_hash: hashed_token,
        label: label
      })
      |> validate_required([:user_id, :token_hash, :label])
      |> validate_length(:label, min: 1, max: 100)
      |> foreign_key_constraint(:user_id)

    {raw_token, changeset}
  end

  @doc """
  Hashes a raw token for database lookup.
  """
  def hash_token(raw_token) do
    :crypto.hash(@hash_algorithm, raw_token)
  end

  @doc """
  Returns true if the token has been revoked.
  """
  def revoked?(%__MODULE__{revoked_at: nil}), do: false
  def revoked?(%__MODULE__{}), do: true
end
