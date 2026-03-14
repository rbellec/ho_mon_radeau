defmodule HoMonRadeauWeb.Admin.TransverseTeamLive.Show do
  use HoMonRadeauWeb, :live_view

  alias HoMonRadeau.Events
  alias HoMonRadeau.Accounts

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    team = Events.get_transverse_team!(id)

    {:ok,
     socket
     |> assign(:page_title, "Équipe - #{team.name}")
     |> assign(:team, team)
     |> assign(:search_query, "")
     |> assign(:search_results, [])}
  end

  @impl true
  def handle_event("search_users", %{"query" => query}, socket) do
    results =
      if String.length(query) >= 2 do
        Accounts.search_users(query)
      else
        []
      end

    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:search_results, results)}
  end

  @impl true
  def handle_event("add_member", %{"user-id" => user_id}, socket) do
    team = socket.assigns.team

    case Events.add_transverse_team_member(team.id, String.to_integer(user_id)) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Membre ajouté.")
         |> assign(:search_query, "")
         |> assign(:search_results, [])
         |> reload_team()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de l'ajout (déjà membre ?).")}
    end
  end

  @impl true
  def handle_event("remove_member", %{"user-id" => user_id}, socket) do
    team = socket.assigns.team

    case Events.remove_transverse_team_member(team.id, String.to_integer(user_id)) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Membre retiré.")
         |> reload_team()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors du retrait.")}
    end
  end

  @impl true
  def handle_event("toggle_coordinator", %{"user-id" => user_id}, socket) do
    team = socket.assigns.team
    member = Events.get_crew_member(team.id, String.to_integer(user_id))

    result =
      if member.is_manager do
        Events.demote_from_manager(team.id, member.user_id)
      else
        Events.promote_to_manager(team.id, member.user_id)
      end

    case result do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Rôle de coordinateur mis à jour.")
         |> reload_team()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de la mise à jour.")}
    end
  end

  defp reload_team(socket) do
    team = Events.get_transverse_team!(socket.assigns.team.id)
    assign(socket, :team, team)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@team.name}
        <:subtitle>
          Équipe transverse — {length(@team.crew_members)} membre{if length(@team.crew_members) != 1,
            do: "s"}
        </:subtitle>
        <:actions>
          <.link navigate={~p"/admin/equipes-transverses"} class="btn btn-ghost btn-sm">
            ← Retour
          </.link>
        </:actions>
      </.header>

      <%= if @team.description do %>
        <p class="mt-4 text-base-content/70">{@team.description}</p>
      <% end %>

      <%!-- Add member search --%>
      <div class="card bg-base-200 mt-6" id="add-member-section">
        <div class="card-body">
          <h3 class="card-title text-sm">Ajouter un membre</h3>
          <form phx-change="search_users" id="search-member-form">
            <input
              type="text"
              name="query"
              value={@search_query}
              placeholder="Rechercher par pseudo ou email..."
              class="input input-bordered input-sm w-full"
              phx-debounce="300"
              autocomplete="off"
            />
          </form>
          <%= if @search_results != [] do %>
            <ul class="mt-2 space-y-1">
              <%= for user <- @search_results do %>
                <li class="flex items-center justify-between p-2 bg-base-100 rounded">
                  <span>
                    {Accounts.display_name(user)}
                    <span class="text-xs text-base-content/50">({user.email})</span>
                  </span>
                  <button
                    class="btn btn-success btn-xs"
                    phx-click="add_member"
                    phx-value-user-id={user.id}
                  >
                    Ajouter
                  </button>
                </li>
              <% end %>
            </ul>
          <% end %>
        </div>
      </div>

      <%!-- Members list --%>
      <div class="mt-6" id="team-members-list">
        <h3 class="text-lg font-bold mb-4">Membres</h3>
        <div class="space-y-2">
          <%= for member <- @team.crew_members do %>
            <div
              class="flex items-center justify-between p-3 bg-base-200 rounded-lg"
              id={"member-#{member.user_id}"}
            >
              <div>
                <span class="font-medium">{Accounts.display_name(member.user)}</span>
                <span class="text-sm text-base-content/50">{member.user.email}</span>
                <%= if member.is_manager do %>
                  <span class="badge badge-secondary badge-xs ml-1">Coordinateur</span>
                <% end %>
              </div>
              <div class="flex gap-1">
                <button
                  class="btn btn-ghost btn-xs"
                  phx-click="toggle_coordinator"
                  phx-value-user-id={member.user_id}
                >
                  <%= if member.is_manager do %>
                    Retirer coordinateur
                  <% else %>
                    Nommer coordinateur
                  <% end %>
                </button>
                <button
                  class="btn btn-ghost btn-xs text-error"
                  phx-click="remove_member"
                  phx-value-user-id={member.user_id}
                  data-confirm="Retirer ce membre de l'équipe ?"
                >
                  Retirer
                </button>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
