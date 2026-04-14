defmodule HoMonRadeauWeb.Api.RaftController do
  use HoMonRadeauWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias HoMonRadeau.Events

  tags(["Rafts"])

  operation(:index,
    summary: "List rafts for the current edition",
    responses: [ok: {"Raft list", "application/json", :map}]
  )

  def index(conn, _params) do
    rafts = Events.list_current_edition_rafts()
    json(conn, %{data: Enum.map(rafts, &serialize_raft/1)})
  end

  operation(:show,
    summary: "Get raft details",
    parameters: [id: [in: :path, type: :integer, required: true]],
    responses: [ok: {"Raft detail", "application/json", :map}]
  )

  def show(conn, %{"id" => id}) do
    raft = Events.get_raft!(id) |> Events.preload_raft_details()
    json(conn, %{data: serialize_raft_detail(raft)})
  end

  operation(:validate,
    summary: "Validate a raft",
    parameters: [id: [in: :path, type: :integer, required: true]],
    responses: [ok: {"Validated raft", "application/json", :map}]
  )

  def validate(conn, %{"id" => id}) do
    raft = Events.get_raft!(id)

    case Events.validate_raft(raft, conn.assigns.current_user) do
      {:ok, raft} -> json(conn, %{data: serialize_raft(raft)})
      {:error, changeset} -> json_error(conn, changeset)
    end
  end

  operation(:invalidate,
    summary: "Revoke raft validation",
    parameters: [id: [in: :path, type: :integer, required: true]],
    responses: [ok: {"Invalidated raft", "application/json", :map}]
  )

  def invalidate(conn, %{"id" => id}) do
    raft = Events.get_raft!(id)

    case Events.invalidate_raft(raft) do
      {:ok, raft} -> json(conn, %{data: serialize_raft(raft)})
      {:error, changeset} -> json_error(conn, changeset)
    end
  end

  defp serialize_raft(raft) do
    crew_count = Map.get(raft, :crew_count, nil)
    max_cap = Map.get(raft, :max_capacity, nil)

    places_remaining =
      if crew_count && max_cap, do: max(0, max_cap - crew_count), else: nil

    %{
      id: raft.id,
      name: raft.name,
      slug: raft.slug,
      description: raft.description,
      forum_url: raft.forum_url,
      validated: raft.validated,
      validated_at: raft.validated_at,
      crew_count: crew_count,
      max_capacity: max_cap,
      open_for_applications: Map.get(raft, :open_for_applications, nil),
      places_remaining: places_remaining,
      inserted_at: raft.inserted_at
    }
  end

  defp serialize_raft_detail(raft) do
    base = serialize_raft(raft)

    crew_members =
      case raft.crew do
        %{crew_members: members} when is_list(members) ->
          Enum.map(members, fn m ->
            %{
              id: m.id,
              user_id: m.user_id,
              is_manager: m.is_manager,
              is_captain: m.is_captain,
              display_name: HoMonRadeau.Accounts.display_name(m.user),
              joined_at: m.inserted_at
            }
          end)

        _ ->
          []
      end

    links =
      case raft.links do
        links when is_list(links) ->
          Enum.map(links, fn l ->
            %{id: l.id, label: l.label, url: l.url, is_public: l.is_public}
          end)

        _ ->
          []
      end

    Map.merge(base, %{crew_members: crew_members, links: links})
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
