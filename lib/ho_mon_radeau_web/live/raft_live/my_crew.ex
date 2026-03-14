defmodule HoMonRadeauWeb.RaftLive.MyCrew do
  use HoMonRadeauWeb, :live_view

  alias HoMonRadeau.Events
  alias HoMonRadeau.Events.CrewMember
  alias HoMonRadeau.Accounts

  @role_labels %{
    "lead_construction" => "Lead construction",
    "cooking" => "Cuisine",
    "safe_contact" => "Interlocuteur SAFE",
    "logistics" => "Logistique",
    "music" => "Musique",
    "decoration" => "Décoration",
    "other" => "Autre"
  }

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    case Events.get_user_crew(user) do
      nil ->
        {:ok,
         socket
         |> put_flash(:info, "Vous n'êtes pas encore membre d'un équipage.")
         |> redirect(to: ~p"/radeaux")}

      crew ->
        my_member = Events.get_crew_member(crew.id, user.id)

        {:ok,
         socket
         |> assign(:my_member, my_member)
         |> assign(:crew, crew)
         |> load_crew_data()}
    end
  end

  @impl true
  def handle_event("accept_request", %{"id" => id}, socket) do
    request = Events.get_join_request!(id)
    user = socket.assigns.current_scope.user

    case Events.accept_join_request(request, user) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "#{Accounts.display_name(request.user)} a rejoint l'équipage !")
         |> load_crew_data()}

      {:error, :user_not_validated} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Cet utilisateur doit d'abord être validé par l'équipe d'accueil."
         )}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de l'acceptation.")}
    end
  end

  @impl true
  def handle_event("reject_request", %{"id" => id}, socket) do
    request = Events.get_join_request!(id)
    user = socket.assigns.current_scope.user

    case Events.reject_join_request(request, user) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Demande refusée.")
         |> load_crew_data()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors du refus.")}
    end
  end

  @impl true
  def handle_event("save_my_roles", %{"roles" => roles}, socket) do
    selected_roles = for {role, "true"} <- roles, do: role

    case Events.update_member_roles(socket.assigns.my_member, selected_roles) do
      {:ok, updated_member} ->
        {:noreply,
         socket
         |> assign(:my_member, updated_member)
         |> put_flash(:info, "Rôles mis à jour.")
         |> load_crew_data()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de la mise à jour des rôles.")}
    end
  end

  @impl true
  def handle_event("save_my_roles", _params, socket) do
    # No roles selected at all
    case Events.update_member_roles(socket.assigns.my_member, []) do
      {:ok, updated_member} ->
        {:noreply,
         socket
         |> assign(:my_member, updated_member)
         |> put_flash(:info, "Rôles mis à jour.")
         |> load_crew_data()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de la mise à jour des rôles.")}
    end
  end

  @impl true
  def handle_event("set_captain", %{"user-id" => user_id}, socket) do
    crew = socket.assigns.crew

    case Events.set_captain(crew.id, String.to_integer(user_id)) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Capitaine mis à jour.")
         |> load_crew_data()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de la nomination du capitaine.")}
    end
  end

  @impl true
  def handle_event("remove_captain", _params, socket) do
    crew = socket.assigns.crew
    Events.remove_captain(crew.id)

    {:noreply,
     socket
     |> put_flash(:info, "Rôle de capitaine retiré.")
     |> load_crew_data()}
  end

  @impl true
  def handle_event("promote_manager", %{"user-id" => user_id}, socket) do
    crew = socket.assigns.crew

    case Events.promote_to_manager(crew.id, String.to_integer(user_id)) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Membre promu gestionnaire.")
         |> load_crew_data()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de la promotion.")}
    end
  end

  @impl true
  def handle_event("demote_manager", %{"user-id" => user_id}, socket) do
    crew = socket.assigns.crew

    case Events.demote_from_manager(crew.id, String.to_integer(user_id)) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Rôle de gestionnaire retiré.")
         |> load_crew_data()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de la rétrogradation.")}
    end
  end

  defp load_crew_data(socket) do
    crew = socket.assigns.crew
    user = socket.assigns.current_scope.user
    raft = Events.get_raft!(crew.raft_id) |> Events.preload_raft_details()
    is_manager = Events.is_crew_manager?(crew, user)
    pending_requests = if is_manager, do: Events.list_pending_join_requests(crew), else: []
    captain = Events.get_captain(crew.id)
    roles_summary = Events.get_roles_summary(crew.id)

    socket
    |> assign(:page_title, "Mon radeau - #{raft.name}")
    |> assign(:raft, raft)
    |> assign(:is_manager, is_manager)
    |> assign(:pending_requests, pending_requests)
    |> assign(:captain, captain)
    |> assign(:roles_summary, roles_summary)
  end

  defp role_label(role), do: Map.get(@role_labels, role, role)

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :available_roles, CrewMember.valid_roles())

    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@raft.name}
        <:subtitle>Page équipage</:subtitle>
        <:actions>
          <.link navigate={~p"/radeaux/#{@raft.slug}"} class="btn btn-ghost btn-sm">
            Voir la page publique
          </.link>
        </:actions>
      </.header>

      <div class="mt-8 grid gap-8 lg:grid-cols-3">
        <div class="lg:col-span-2 space-y-8">
          <%!-- Pending join requests (managers only) --%>
          <%= if @is_manager && length(@pending_requests) > 0 do %>
            <div class="card bg-warning/10 border border-warning">
              <div class="card-body">
                <h3 class="card-title text-warning">
                  Demandes d'adhésion ({length(@pending_requests)})
                </h3>
                <div class="space-y-4 mt-2">
                  <%= for request <- @pending_requests do %>
                    <div class="flex items-start justify-between gap-4 p-3 bg-base-100 rounded-lg">
                      <div>
                        <p class="font-medium">{Accounts.display_name(request.user)}</p>
                        <%= if request.user.validated do %>
                          <span class="badge badge-success badge-sm">Validé·e</span>
                        <% else %>
                          <span class="badge badge-warning badge-sm">En attente validation</span>
                        <% end %>
                        <%= if request.message do %>
                          <p class="text-sm text-base-content/70 mt-1 italic">
                            "{request.message}"
                          </p>
                        <% end %>
                        <p class="text-xs text-base-content/50 mt-1">
                          Demande envoyée le {Calendar.strftime(
                            request.inserted_at,
                            "%d/%m/%Y à %H:%M"
                          )}
                        </p>
                      </div>
                      <div class="flex gap-2">
                        <%= if request.user.validated do %>
                          <button
                            class="btn btn-success btn-sm"
                            phx-click="accept_request"
                            phx-value-id={request.id}
                          >
                            Accepter
                          </button>
                        <% end %>
                        <button
                          class="btn btn-ghost btn-sm"
                          phx-click="reject_request"
                          phx-value-id={request.id}
                          data-confirm="Êtes-vous sûr·e de vouloir refuser cette demande ?"
                        >
                          Refuser
                        </button>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
          <% end %>

          <%!-- Roles summary --%>
          <div class="card bg-base-200" id="roles-summary">
            <div class="card-body">
              <h3 class="card-title">État des rôles</h3>
              <div class="space-y-2 mt-2">
                <div class="flex items-center gap-2">
                  <%= if @captain do %>
                    <.icon name="hero-check-circle-mini" class="size-4 text-success" />
                    <span class="font-medium">Capitaine :</span>
                    <span>{Accounts.display_name(@captain.user)}</span>
                  <% else %>
                    <.icon name="hero-exclamation-triangle-mini" class="size-4 text-warning" />
                    <span class="font-medium text-warning">Capitaine : personne</span>
                  <% end %>
                </div>
                <%= for role <- @available_roles do %>
                  <div class="flex items-center gap-2">
                    <%= if @roles_summary[role] != [] do %>
                      <.icon name="hero-check-circle-mini" class="size-4 text-success" />
                      <span class="font-medium">{role_label(role)} :</span>
                      <span>{Enum.join(@roles_summary[role], ", ")}</span>
                    <% else %>
                      <.icon name="hero-exclamation-triangle-mini" class="size-4 text-warning" />
                      <span class="font-medium text-warning">{role_label(role)} : personne</span>
                    <% end %>
                  </div>
                <% end %>
              </div>
            </div>
          </div>

          <%!-- My roles (self-declaration) --%>
          <div class="card bg-base-200" id="my-roles">
            <div class="card-body">
              <h3 class="card-title">Mon profil dans l'équipage</h3>
              <form phx-submit="save_my_roles" id="my-roles-form">
                <div class="space-y-2 mt-2">
                  <%= for role <- @available_roles do %>
                    <label class="label cursor-pointer justify-start gap-3">
                      <input
                        type="checkbox"
                        name={"roles[#{role}]"}
                        value="true"
                        checked={role in (@my_member.roles || [])}
                        class="checkbox checkbox-primary checkbox-sm"
                      />
                      <span class="label-text">{role_label(role)}</span>
                    </label>
                  <% end %>
                </div>
                <p class="text-xs text-base-content/50 mt-2">
                  Le rôle de capitaine est attribué par les gestionnaires.
                </p>
                <div class="mt-4">
                  <.button variant="primary" phx-disable-with="Enregistrement...">
                    Enregistrer mes rôles
                  </.button>
                </div>
              </form>
            </div>
          </div>

          <%!-- Raft info --%>
          <div class="card bg-base-200">
            <div class="card-body">
              <h3 class="card-title">Informations</h3>

              <%= if @raft.description do %>
                <div class="mt-2">
                  <p class="text-sm font-medium text-base-content/60">Description</p>
                  <p class="whitespace-pre-wrap">{@raft.description}</p>
                </div>
              <% end %>

              <%= if @raft.forum_url do %>
                <div class="mt-4">
                  <p class="text-sm font-medium text-base-content/60">Lien forum</p>
                  <a href={@raft.forum_url} target="_blank" class="link link-primary">
                    {@raft.forum_url}
                  </a>
                </div>
              <% end %>

              <div class="mt-4">
                <p class="text-sm font-medium text-base-content/60">Statut</p>
                <%= if @raft.validated do %>
                  <span class="badge badge-success">Radeau validé</span>
                <% else %>
                  <span class="badge badge-ghost">En attente de validation admin</span>
                <% end %>
              </div>
            </div>
          </div>

          <%!-- Quick links --%>
          <div class="card bg-base-200">
            <div class="card-body">
              <h3 class="card-title">Actions</h3>
              <div class="flex flex-wrap gap-2 mt-2">
                <.link navigate={~p"/fiche-inscription"} class="btn btn-primary btn-sm">
                  Ma fiche d'inscription
                </.link>
                <%= if @raft.forum_url do %>
                  <a href={@raft.forum_url} target="_blank" class="btn btn-ghost btn-sm">
                    Discussion forum
                  </a>
                <% end %>
              </div>
            </div>
          </div>
        </div>

        <%!-- Crew members sidebar --%>
        <div>
          <div class="card bg-base-200">
            <div class="card-body">
              <h3 class="card-title">
                Équipage <span class="badge badge-ghost">{length(@raft.crew.crew_members)}</span>
              </h3>

              <ul class="space-y-4 mt-2" id="crew-members-list">
                <%= for member <- @raft.crew.crew_members do %>
                  <li class="p-3 bg-base-100 rounded-lg">
                    <div class="flex items-center justify-between">
                      <div>
                        <p class="font-medium">{Accounts.display_name(member.user)}</p>
                        <div class="flex flex-wrap gap-1 mt-1">
                          <%= if member.is_captain do %>
                            <span class="badge badge-primary badge-xs">Capitaine ★</span>
                          <% end %>
                          <%= if member.is_manager do %>
                            <span class="badge badge-secondary badge-xs">Gestionnaire</span>
                          <% end %>
                          <%= for role <- member.roles || [] do %>
                            <span class="badge badge-ghost badge-xs">{role_label(role)}</span>
                          <% end %>
                        </div>
                      </div>
                    </div>
                    <%!-- Manager actions --%>
                    <%= if @is_manager && member.user_id != @current_scope.user.id do %>
                      <div class="flex flex-wrap gap-1 mt-2 pt-2 border-t border-base-200">
                        <%= if member.is_captain do %>
                          <button
                            class="btn btn-ghost btn-xs"
                            phx-click="remove_captain"
                            data-confirm="Retirer le rôle de capitaine ?"
                          >
                            Retirer capitaine
                          </button>
                        <% else %>
                          <button
                            class="btn btn-ghost btn-xs"
                            phx-click="set_captain"
                            phx-value-user-id={member.user_id}
                            data-confirm={
                              if(@captain,
                                do:
                                  "Attention : #{Accounts.display_name(@captain.user)} est actuellement capitaine. Cette action lui retirera ce rôle. Continuer ?",
                                else: "Nommer #{Accounts.display_name(member.user)} capitaine ?"
                              )
                            }
                          >
                            Nommer capitaine
                          </button>
                        <% end %>
                        <%= if member.is_manager do %>
                          <button
                            class="btn btn-ghost btn-xs"
                            phx-click="demote_manager"
                            phx-value-user-id={member.user_id}
                            data-confirm="Retirer le rôle de gestionnaire ?"
                          >
                            Retirer gestionnaire
                          </button>
                        <% else %>
                          <button
                            class="btn btn-ghost btn-xs"
                            phx-click="promote_manager"
                            phx-value-user-id={member.user_id}
                          >
                            Nommer gestionnaire
                          </button>
                        <% end %>
                      </div>
                    <% end %>
                  </li>
                <% end %>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
