defmodule HoMonRadeauWeb.Plugs.ApiAuth do
  @moduledoc """
  Plug for authenticating API requests via Bearer token.
  Extracts the token from the Authorization header and loads the user.
  """
  import Plug.Conn

  alias HoMonRadeau.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         %{} = user <- Accounts.authenticate_by_api_token(token) do
      conn
      |> assign(:current_user, user)
      |> assign(:api_authenticated, true)
    else
      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(%{error: "Invalid or missing API token"}))
        |> halt()
    end
  end
end
