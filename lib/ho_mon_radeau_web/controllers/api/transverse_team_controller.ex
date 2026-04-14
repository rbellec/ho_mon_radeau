defmodule HoMonRadeauWeb.Api.TransverseTeamController do
  use HoMonRadeauWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias HoMonRadeau.Events

  tags(["Transverse Teams"])

  operation(:index,
    summary: "List all transverse teams",
    responses: [ok: {"Team list", "application/json", :map}]
  )

  def index(conn, _params) do
    teams = Events.list_transverse_teams()
    json(conn, %{data: Enum.map(teams, &serialize_team/1)})
  end

  operation(:show,
    summary: "Get team details with members",
    parameters: [id: [in: :path, type: :integer, required: true]],
    responses: [ok: {"Team detail", "application/json", :map}]
  )

  def show(conn, %{"id" => id}) do
    team = Events.get_transverse_team!(id)
    json(conn, %{data: serialize_team_detail(team)})
  end

  operation(:create,
    summary: "Create a new transverse team",
    responses: [ok: {"Created team", "application/json", :map}]
  )

  def create(conn, params) do
    case Events.create_transverse_team(params) do
      {:ok, team} ->
        conn |> put_status(:created) |> json(%{data: serialize_team(team)})

      {:error, changeset} ->
        json_error(conn, changeset)
    end
  end

  operation(:add_member,
    summary: "Add a member to a transverse team",
    parameters: [id: [in: :path, type: :integer, required: true]],
    responses: [ok: {"Added member", "application/json", :map}]
  )

  def add_member(conn, %{"id" => id} = params) do
    team = Events.get_transverse_team!(id)
    user_id = Map.fetch!(params, "user_id")
    opts = if params["is_manager"], do: [is_manager: true], else: []

    case Events.add_transverse_team_member(team, user_id, opts) do
      {:ok, _member} ->
        team = Events.get_transverse_team!(id)
        json(conn, %{data: serialize_team_detail(team)})

      {:error, changeset} ->
        json_error(conn, changeset)
    end
  end

  operation(:remove_member,
    summary: "Remove a member from a transverse team",
    parameters: [
      id: [in: :path, type: :integer, required: true],
      user_id: [in: :path, type: :integer, required: true]
    ],
    responses: [ok: {"Removed", "application/json", :map}]
  )

  def remove_member(conn, %{"id" => id, "user_id" => user_id}) do
    team = Events.get_transverse_team!(id)

    case Events.remove_transverse_team_member(team, user_id) do
      {:ok, _} ->
        json(conn, %{data: %{removed: true}})

      {:error, reason} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: inspect(reason)})
    end
  end

  defp serialize_team(team) do
    %{
      id: team.id,
      name: team.name,
      description: team.description,
      transverse_type: team.transverse_type,
      member_count: Map.get(team, :member_count, nil),
      inserted_at: team.inserted_at
    }
  end

  defp serialize_team_detail(team) do
    base = serialize_team(team)

    members =
      case team.crew_members do
        members when is_list(members) ->
          Enum.map(members, fn m ->
            %{
              id: m.id,
              user_id: m.user_id,
              is_manager: m.is_manager,
              display_name:
                if(Ecto.assoc_loaded?(m.user),
                  do: HoMonRadeau.Accounts.display_name(m.user),
                  else: nil
                )
            }
          end)

        _ ->
          []
      end

    Map.put(base, :members, members)
  end

  defp json_error(conn, changeset) do
    errors =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
          opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
        end)
      end)

    conn |> put_status(:unprocessable_entity) |> json(%{errors: errors})
  end
end
