defmodule HoMonRadeauWeb.Api.ErrorHelpers do
  @moduledoc """
  Shared JSON error rendering for the API controllers.
  """

  import Phoenix.Controller, only: [json: 2]
  import Plug.Conn, only: [put_status: 2]

  @doc """
  Renders an `%Ecto.Changeset{}`'s errors as a 422 JSON response.
  """
  def json_error(conn, changeset) do
    errors =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
          opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
        end)
      end)

    conn |> put_status(:unprocessable_entity) |> json(%{errors: errors})
  end
end
