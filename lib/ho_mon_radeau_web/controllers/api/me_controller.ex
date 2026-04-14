defmodule HoMonRadeauWeb.Api.MeController do
  use HoMonRadeauWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias HoMonRadeau.{Accounts, Events, CUF, Drums}

  tags(["Me"])

  operation(:show,
    summary: "Get current user dashboard with status and next actions",
    responses: [ok: {"Dashboard", "application/json", %OpenApiSpex.Schema{type: :object}}]
  )

  def show(conn, _params) do
    user = conn.assigns.current_user
    edition = Events.get_current_edition()
    crew_member = get_crew_member(user, edition)
    crew = if crew_member, do: crew_member.crew, else: nil

    form_status =
      if edition && crew,
        do: Events.registration_form_status(user, edition.id),
        else: :missing

    cuf_summary = if crew, do: CUF.get_crew_cuf_summary(crew.id), else: nil
    drums_summary = if crew, do: Drums.get_crew_summary(crew.id), else: nil
    transverse_teams = Events.get_user_transverse_teams(user)
    join_requests = Events.list_user_join_requests(user)

    next_actions = compute_next_actions(user, crew, form_status, cuf_summary)

    json(conn, %{
      data: %{
        profile: serialize_profile(user),
        crew: serialize_crew(crew_member, crew),
        registration_form: %{status: form_status},
        cuf: serialize_cuf(cuf_summary),
        drums: serialize_drums(drums_summary),
        transverse_teams:
          Enum.map(transverse_teams, fn t ->
            %{id: t.id, name: t.name, transverse_type: t.transverse_type}
          end),
        join_requests:
          Enum.map(join_requests, fn jr ->
            %{
              id: jr.id,
              status: jr.status,
              raft_name: jr.crew.raft.name,
              inserted_at: jr.inserted_at
            }
          end),
        next_actions: next_actions
      }
    })
  end

  defp get_crew_member(user, nil), do: ignore(user)

  defp get_crew_member(user, edition) do
    import Ecto.Query

    HoMonRadeau.Events.CrewMember
    |> where([cm], cm.user_id == ^user.id)
    |> join(:inner, [cm], c in HoMonRadeau.Events.Crew, on: c.id == cm.crew_id)
    |> where([_cm, c], c.edition_id == ^edition.id and c.is_transverse == false)
    |> preload(crew: [:raft])
    |> HoMonRadeau.Repo.one()
  end

  defp ignore(_), do: nil

  defp serialize_profile(user) do
    %{
      id: user.id,
      email: user.email,
      nickname: user.nickname,
      first_name: user.first_name,
      last_name: user.last_name,
      validated: user.validated,
      is_admin: user.is_admin,
      can_participate: Accounts.can_participate?(user)
    }
  end

  defp serialize_crew(nil, _), do: nil

  defp serialize_crew(member, crew) do
    raft = crew.raft

    role =
      cond do
        member.is_captain -> "captain"
        member.is_manager -> "manager"
        true -> "member"
      end

    %{
      crew_id: crew.id,
      raft_id: raft.id,
      raft_name: raft.name,
      raft_slug: raft.slug,
      forum_url: raft.forum_url,
      role: role,
      crew_count: Events.count_crew_members(crew.id),
      max_capacity: raft.max_capacity,
      open_for_applications: raft.open_for_applications
    }
  end

  defp serialize_cuf(nil), do: nil

  defp serialize_cuf(summary) do
    %{
      total_validated_participants: summary.total_validated_participants,
      total_validated_amount: summary.total_validated_amount,
      has_pending: summary.pending != nil
    }
  end

  defp serialize_drums(nil), do: nil

  defp serialize_drums(summary) do
    %{
      total_paid_quantity: summary.total_paid_quantity,
      total_paid_amount: summary.total_paid_amount,
      pending_quantity: summary.pending_quantity,
      pending_amount: summary.pending_amount
    }
  end

  defp compute_next_actions(user, crew, form_status, cuf_summary) do
    []
    |> maybe_add(profile_incomplete?(user), %{
      key: "complete_profile",
      message: "Complétez votre profil (prénom et nom)"
    })
    |> maybe_add(not user.validated, %{
      key: "awaiting_validation",
      message: "Votre compte est en attente de validation par l'équipe d'accueil"
    })
    |> maybe_add(is_nil(crew) and user.validated, %{
      key: "join_raft",
      message: "Rejoignez un radeau"
    })
    |> maybe_add(form_status == :missing and not is_nil(crew), %{
      key: "submit_form",
      message: "Envoyez votre fiche d'inscription"
    })
    |> maybe_add(form_status == :rejected, %{
      key: "resubmit_form",
      message: "Votre fiche a été rejetée, renvoyez-la"
    })
    |> maybe_add(needs_cuf_action?(cuf_summary), %{
      key: "cuf_action",
      message: "Déclarez et payez votre CUF"
    })
    |> Enum.reverse()
  end

  defp profile_incomplete?(user) do
    is_nil(user.first_name) or user.first_name == "" or
      is_nil(user.last_name) or user.last_name == ""
  end

  defp needs_cuf_action?(nil), do: false
  defp needs_cuf_action?(%{total_validated_participants: 0, pending: nil}), do: true
  defp needs_cuf_action?(_), do: false

  defp maybe_add(list, true, item), do: [item | list]
  defp maybe_add(list, false, _item), do: list
end
