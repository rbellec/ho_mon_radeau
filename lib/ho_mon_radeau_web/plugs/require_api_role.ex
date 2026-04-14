defmodule HoMonRadeauWeb.Plugs.RequireApiRole do
  @moduledoc """
  Plug that checks authorization for API requests.
  Must be used after ApiAuth (which sets `current_user`).

  Supports three roles:
  - `:admin` — requires `is_admin`
  - `:validated` — requires `validated`
  - `:raft_manager` — requires manager or captain of the raft (admins always pass)
  """
  import Plug.Conn

  alias HoMonRadeau.Events

  def init(opts), do: opts

  def call(conn, role: :admin) do
    if conn.assigns.current_user.is_admin do
      conn
    else
      forbidden(conn)
    end
  end

  def call(conn, role: :validated) do
    if conn.assigns.current_user.validated do
      conn
    else
      forbidden(conn)
    end
  end

  def call(conn, role: :raft_manager) do
    user = conn.assigns.current_user

    if user.is_admin do
      conn
    else
      raft_id = conn.path_params["raft_id"] || conn.path_params["id"]
      raft = Events.get_raft!(raft_id)
      crew = Events.get_crew_by_raft(raft)

      if crew && Events.is_manager_or_captain?(crew.id, user.id) do
        conn
      else
        forbidden(conn)
      end
    end
  end

  defp forbidden(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(403, Jason.encode!(%{error: "Forbidden"}))
    |> halt()
  end
end
