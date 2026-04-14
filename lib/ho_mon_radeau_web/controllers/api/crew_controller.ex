defmodule HoMonRadeauWeb.Api.CrewController do
  use HoMonRadeauWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias HoMonRadeau.Events

  plug HoMonRadeauWeb.Plugs.RequireApiRole, role: :raft_manager

  tags(["Crew"])

  operation(:show,
    summary: "List crew members for a raft",
    parameters: [raft_id: [in: :path, type: :integer, required: true]],
    responses: [ok: {"Crew members", "application/json", :map}]
  )

  def show(conn, %{"raft_id" => raft_id}) do
    raft = Events.get_raft!(raft_id)
    crew = Events.get_crew_by_raft(raft)
    members = Events.list_crew_members(crew)

    json(conn, %{
      data: %{
        raft_id: raft.id,
        raft_name: raft.name,
        members: Enum.map(members, &serialize_member/1)
      }
    })
  end

  operation(:promote_manager,
    summary: "Promote a crew member to manager",
    parameters: [
      raft_id: [in: :path, type: :integer, required: true],
      member_id: [in: :path, type: :integer, required: true]
    ],
    responses: [ok: {"Updated member", "application/json", :map}]
  )

  def promote_manager(conn, %{"raft_id" => raft_id, "member_id" => member_id}) do
    raft = Events.get_raft!(raft_id)
    crew = Events.get_crew_by_raft(raft)
    member = Events.get_crew_member(crew, member_id)

    case Events.promote_to_manager(crew, member) do
      {:ok, member} -> json(conn, %{data: serialize_member(member)})
      {:error, changeset} -> json_error(conn, changeset)
    end
  end

  operation(:demote_manager,
    summary: "Demote a crew member from manager",
    parameters: [
      raft_id: [in: :path, type: :integer, required: true],
      member_id: [in: :path, type: :integer, required: true]
    ],
    responses: [ok: {"Updated member", "application/json", :map}]
  )

  def demote_manager(conn, %{"raft_id" => raft_id, "member_id" => member_id}) do
    raft = Events.get_raft!(raft_id)
    crew = Events.get_crew_by_raft(raft)
    member = Events.get_crew_member(crew, member_id)

    case Events.demote_from_manager(crew, member) do
      {:ok, member} -> json(conn, %{data: serialize_member(member)})
      {:error, changeset} -> json_error(conn, changeset)
    end
  end

  operation(:set_captain,
    summary: "Set a crew member as captain",
    parameters: [
      raft_id: [in: :path, type: :integer, required: true],
      member_id: [in: :path, type: :integer, required: true]
    ],
    responses: [ok: {"Updated member", "application/json", :map}]
  )

  def set_captain(conn, %{"raft_id" => raft_id, "member_id" => member_id}) do
    raft = Events.get_raft!(raft_id)
    crew = Events.get_crew_by_raft(raft)
    member = Events.get_crew_member(crew, member_id)

    case Events.set_captain(crew, member) do
      {:ok, member} -> json(conn, %{data: serialize_member(member)})
      {:error, changeset} -> json_error(conn, changeset)
    end
  end

  operation(:remove_member,
    summary: "Remove a member from the crew",
    parameters: [
      raft_id: [in: :path, type: :integer, required: true],
      member_id: [in: :path, type: :integer, required: true]
    ],
    responses: [ok: {"Success", "application/json", :map}]
  )

  def remove_member(conn, %{"raft_id" => raft_id, "member_id" => member_id}) do
    raft = Events.get_raft!(raft_id)
    crew = Events.get_crew_by_raft(raft)
    member = Events.get_crew_member(crew, member_id)

    case Events.remove_crew_member(crew, member) do
      {:ok, _} -> json(conn, %{data: %{removed: true}})
      {:error, changeset} -> json_error(conn, changeset)
    end
  end

  defp serialize_member(member) do
    %{
      id: member.id,
      user_id: member.user_id,
      is_manager: member.is_manager,
      is_captain: member.is_captain,
      roles: Map.get(member, :roles, []),
      display_name:
        if(Ecto.assoc_loaded?(member.user),
          do: HoMonRadeau.Accounts.display_name(member.user),
          else: nil
        ),
      joined_at: member.inserted_at
    }
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
