defmodule HoMonRadeauWeb.Api.JoinRequestController do
  use HoMonRadeauWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias HoMonRadeau.Events

  plug HoMonRadeauWeb.Plugs.RequireApiRole, [role: :raft_manager] when action == :index
  plug :authorize_join_request when action in [:accept, :reject]

  tags(["Join Requests"])

  operation(:index,
    summary: "List pending join requests for a crew",
    parameters: [raft_id: [in: :path, type: :integer, required: true]],
    responses: [ok: {"Join requests", "application/json", %OpenApiSpex.Schema{type: :object}}]
  )

  def index(conn, %{"raft_id" => raft_id}) do
    raft = Events.get_raft!(raft_id)
    crew = Events.get_crew_by_raft(raft)
    requests = Events.list_pending_join_requests(crew)
    json(conn, %{data: Enum.map(requests, &serialize_request/1)})
  end

  operation(:accept,
    summary: "Accept a join request",
    parameters: [id: [in: :path, type: :integer, required: true]],
    responses: [ok: {"Accepted", "application/json", %OpenApiSpex.Schema{type: :object}}]
  )

  def accept(conn, %{"id" => id}) do
    request = conn.assigns[:join_request] || Events.get_join_request!(id)

    case Events.accept_join_request(request, conn.assigns.current_user) do
      {:ok, _} ->
        json(conn, %{data: %{accepted: true}})

      {:error, reason} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: inspect(reason)})
    end
  end

  operation(:reject,
    summary: "Reject a join request",
    parameters: [id: [in: :path, type: :integer, required: true]],
    responses: [ok: {"Rejected", "application/json", %OpenApiSpex.Schema{type: :object}}]
  )

  def reject(conn, %{"id" => id}) do
    request = conn.assigns[:join_request] || Events.get_join_request!(id)

    case Events.reject_join_request(request, conn.assigns.current_user) do
      {:ok, _} ->
        json(conn, %{data: %{rejected: true}})

      {:error, reason} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: inspect(reason)})
    end
  end

  defp authorize_join_request(conn, _opts) do
    user = conn.assigns.current_user

    if user.is_admin do
      conn
    else
      request = Events.get_join_request!(conn.path_params["id"])

      if Events.is_manager_or_captain?(request.crew_id, user.id) do
        assign(conn, :join_request, request)
      else
        conn
        |> put_status(:forbidden)
        |> json(%{error: "Forbidden"})
        |> halt()
      end
    end
  end

  defp serialize_request(request) do
    %{
      id: request.id,
      user_id: request.user_id,
      status: request.status,
      message: request.message,
      display_name:
        if(Ecto.assoc_loaded?(request.user),
          do: HoMonRadeau.Accounts.display_name(request.user),
          else: nil
        ),
      inserted_at: request.inserted_at
    }
  end
end
