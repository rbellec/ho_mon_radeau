defmodule Mix.Tasks.Mcp.Server do
  @moduledoc """
  Start the MCP server over STDIO for Claude Code / Claude Desktop.

  Usage:
      mix mcp.server
  """
  use Mix.Task

  @shortdoc "Start MCP server (stdio transport)"

  @impl true
  def run(_args) do
    # Start the full application (Repo, PubSub, etc.) but NOT the web endpoint
    Application.put_env(:ho_mon_radeau, HoMonRadeauWeb.Endpoint, server: false)
    {:ok, _} = Application.ensure_all_started(:ho_mon_radeau)

    # Verify an admin user exists
    admin = HoMonRadeau.MCP.Helpers.get_system_admin()

    if is_nil(admin) do
      Mix.shell().error(
        "WARNING: No admin user found in the database. " <>
          "Write operations will fail. Create an admin user first."
      )
    end

    # Start the MCP server with STDIO transport
    {:ok, _pid} =
      HoMonRadeau.MCP.Server.start_link(
        transport: :stdio,
        name: "ho-mon-radeau-admin",
        version: "1.0.0"
      )

    # Keep the process alive
    Process.sleep(:infinity)
  end
end
