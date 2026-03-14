defmodule HoMonRadeauWeb.Admin.UserKaffy do
  @moduledoc """
  Kaffy admin customization for User schema.
  """

  def index(_schema) do
    [
      email: nil,
      nickname: nil,
      first_name: nil,
      last_name: nil,
      validated: nil,
      is_admin: nil,
      inserted_at: %{name: "Inscrit·e le"}
    ]
  end

  def form_fields(_schema) do
    [
      email: %{readonly: true},
      nickname: nil,
      first_name: nil,
      last_name: nil,
      phone_number: nil,
      validated: nil,
      is_admin: nil
    ]
  end

  def search_fields(_schema) do
    [:email, :nickname, :first_name, :last_name]
  end

  def ordering(_schema) do
    [desc: :inserted_at]
  end
end
