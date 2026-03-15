defmodule HoMonRadeauWeb.MCPController do
  @moduledoc """
  Controller for MCP HTTP/SSE transport.
  Authenticates via Bearer token, then delegates to the MCP server.
  """
  use HoMonRadeauWeb, :controller

  alias HoMonRadeau.Accounts
  alias HoMonRadeau.MCP.Server, as: MCPServer

  @doc """
  Handle MCP requests (POST for RPC, GET for SSE).
  Authentication is done via Bearer token in the Authorization header.
  """
  def handle(conn, _params) do
    with {:ok, user} <- authenticate(conn),
         :ok <- authorize(user) do
      # Store the authenticated user in process dictionary for the MCP server to use
      Process.put(:mcp_current_user, user)

      # Delegate to ExMCP.HttpPlug
      opts =
        ExMCP.HttpPlug.init(
          handler: MCPServer,
          server_info: %{name: "ho-mon-radeau-admin", version: "1.0.0"},
          cors_enabled: true,
          sse_enabled: true
        )

      ExMCP.HttpPlug.call(conn, opts)
    else
      {:error, :unauthorized} ->
        conn
        |> put_status(401)
        |> json(%{error: "Token API invalide ou manquant."})

      {:error, :forbidden} ->
        conn
        |> put_status(403)
        |> json(%{error: "Accès réservé aux administrateurs."})
    end
  end

  defp authenticate(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        case Accounts.authenticate_by_api_token(token) do
          %{} = user -> {:ok, user}
          nil -> {:error, :unauthorized}
        end

      _ ->
        {:error, :unauthorized}
    end
  end

  defp authorize(user) do
    if user.is_admin do
      :ok
    else
      {:error, :forbidden}
    end
  end
end
