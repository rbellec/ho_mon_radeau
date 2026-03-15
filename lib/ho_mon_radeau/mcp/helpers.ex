defmodule HoMonRadeau.MCP.Helpers do
  @moduledoc """
  Shared serialization helpers for MCP tools and resources.
  """

  alias HoMonRadeau.Accounts
  import Ecto.Query

  def serialize_user(user) do
    %{
      id: user.id,
      email: user.email,
      nickname: user.nickname,
      display_name: Accounts.display_name(user),
      validated: user.validated,
      is_admin: user.is_admin,
      first_name: user.first_name,
      last_name: user.last_name,
      confirmed: not is_nil(user.confirmed_at),
      inserted_at: to_string(user.inserted_at)
    }
  end

  def serialize_raft(raft) do
    %{
      id: raft.id,
      name: raft.name,
      slug: raft.slug,
      validated: raft.validated,
      description_short: raft.description_short,
      crew_count: Map.get(raft, :crew_count, nil)
    }
  end

  def serialize_raft_detail(raft) do
    base = serialize_raft(raft)

    crew_members =
      if Ecto.assoc_loaded?(raft.crew) and Ecto.assoc_loaded?(raft.crew.crew_members) do
        Enum.map(raft.crew.crew_members, &serialize_crew_member/1)
      else
        []
      end

    links =
      if Ecto.assoc_loaded?(raft.links) do
        Enum.map(raft.links, &serialize_raft_link/1)
      else
        []
      end

    Map.merge(base, %{
      description: raft.description,
      forum_url: raft.forum_url,
      crew_id: if(Ecto.assoc_loaded?(raft.crew), do: raft.crew.id),
      crew_members: crew_members,
      links: links
    })
  end

  def serialize_crew_member(member) do
    %{
      id: member.id,
      user_id: member.user_id,
      display_name: if(Ecto.assoc_loaded?(member.user), do: Accounts.display_name(member.user)),
      is_manager: member.is_manager,
      is_captain: member.is_captain,
      roles: member.roles || [],
      participation_status: member.participation_status
    }
  end

  def serialize_join_request(request) do
    %{
      id: request.id,
      user_id: request.user_id,
      user_display_name:
        if(Ecto.assoc_loaded?(request.user), do: Accounts.display_name(request.user)),
      user_validated: if(Ecto.assoc_loaded?(request.user), do: request.user.validated),
      message: request.message,
      status: request.status,
      inserted_at: to_string(request.inserted_at)
    }
  end

  def serialize_registration_form(form) do
    %{
      id: form.id,
      user_id: form.user_id,
      user_email: if(Ecto.assoc_loaded?(form.user), do: form.user.email),
      form_type: form.form_type,
      status: form.status,
      file_name: form.file_name,
      rejection_reason: form.rejection_reason,
      uploaded_at: to_string(form.uploaded_at),
      reviewed_at: if(form.reviewed_at, do: to_string(form.reviewed_at))
    }
  end

  def serialize_drum_request(request) do
    %{
      id: request.id,
      crew_id: request.crew_id,
      raft_name:
        if(Ecto.assoc_loaded?(request.crew) and Ecto.assoc_loaded?(request.crew.raft),
          do: request.crew.raft.name
        ),
      quantity: request.quantity,
      unit_price: to_string(request.unit_price),
      total_amount: to_string(request.total_amount),
      status: request.status,
      note: request.note,
      inserted_at: to_string(request.inserted_at)
    }
  end

  def serialize_cuf_declaration(decl) do
    %{
      id: decl.id,
      crew_id: decl.crew_id,
      raft_name:
        if(Ecto.assoc_loaded?(decl.crew) and Ecto.assoc_loaded?(decl.crew.raft),
          do: decl.crew.raft.name
        ),
      participant_count: decl.participant_count,
      total_amount: to_string(decl.total_amount),
      status: decl.status,
      inserted_at: to_string(decl.inserted_at)
    }
  end

  def serialize_transverse_team(team) do
    %{
      id: team.id,
      name: team.name,
      transverse_type: team.transverse_type,
      description: team.description,
      member_count: Map.get(team, :member_count, nil)
    }
  end

  def serialize_raft_link(link) do
    %{
      id: link.id,
      title: link.title,
      url: link.url,
      is_public: link.is_public,
      position: link.position
    }
  end

  @doc """
  Get the current authenticated user for MCP operations.
  In HTTP mode, the user is stored in process dictionary by the MCP controller.
  In STDIO mode, falls back to the first admin user in the database.
  """
  def get_current_admin do
    case Process.get(:mcp_current_user) do
      %{} = user -> user
      nil -> get_system_admin()
    end
  end

  @doc """
  Get the first admin user from the database.
  Fallback for STDIO transport where no HTTP auth is available.
  """
  def get_system_admin do
    HoMonRadeau.Repo.one(
      from(u in HoMonRadeau.Accounts.User,
        where: u.is_admin == true,
        limit: 1
      )
    )
  end

  @doc """
  Format an ok result as MCP tool content.
  """
  def ok_result(data) do
    {:ok, %{content: [%{type: "text", text: Jason.encode!(data, pretty: true)}]}, %{}}
  end

  @doc """
  Format an error result as MCP tool content.
  """
  def error_result(message) do
    {:error, message, %{}}
  end
end
