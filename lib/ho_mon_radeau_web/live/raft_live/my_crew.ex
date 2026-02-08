defmodule HoMonRadeauWeb.RaftLive.MyCrew do
  use HoMonRadeauWeb, :live_view

  alias HoMonRadeau.Events
  alias HoMonRadeau.Accounts

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
        raft = Events.get_raft!(crew.raft_id)
        raft = Events.preload_raft_details(raft)
        is_manager = Events.is_crew_manager?(crew, user)
        pending_requests = if is_manager, do: Events.list_pending_join_requests(crew), else: []

        {:ok,
         socket
         |> assign(:page_title, "Mon radeau - #{raft.name}")
         |> assign(:raft, raft)
         |> assign(:crew, crew)
         |> assign(:is_manager, is_manager)
         |> assign(:pending_requests, pending_requests)}
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
         |> reload_data()}

      {:error, :user_not_validated} ->
        {:noreply, put_flash(socket, :error, "Cet utilisateur doit d'abord être validé par l'équipe d'accueil.")}

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
         |> reload_data()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors du refus.")}
    end
  end

  defp reload_data(socket) do
    crew = socket.assigns.crew
    raft = Events.get_raft!(crew.raft_id) |> Events.preload_raft_details()
    pending_requests = if socket.assigns.is_manager, do: Events.list_pending_join_requests(crew), else: []

    socket
    |> assign(:raft, raft)
    |> assign(:pending_requests, pending_requests)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      <%= @raft.name %>
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
                Demandes d'adhésion (<%= length(@pending_requests) %>)
              </h3>
              <div class="space-y-4 mt-2">
                <%= for request <- @pending_requests do %>
                  <div class="flex items-start justify-between gap-4 p-3 bg-base-100 rounded-lg">
                    <div>
                      <p class="font-medium"><%= Accounts.display_name(request.user) %></p>
                      <%= if request.user.validated do %>
                        <span class="badge badge-success badge-sm">Validé·e</span>
                      <% else %>
                        <span class="badge badge-warning badge-sm">En attente validation</span>
                      <% end %>
                      <%= if request.message do %>
                        <p class="text-sm text-base-content/70 mt-1 italic">
                          "<%= request.message %>"
                        </p>
                      <% end %>
                      <p class="text-xs text-base-content/50 mt-1">
                        Demande envoyée le <%= Calendar.strftime(request.inserted_at, "%d/%m/%Y à %H:%M") %>
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

        <%!-- Raft info --%>
        <div class="card bg-base-200">
          <div class="card-body">
            <h3 class="card-title">Informations</h3>

            <%= if @raft.description do %>
              <div class="mt-2">
                <p class="text-sm font-medium text-base-content/60">Description</p>
                <p class="whitespace-pre-wrap"><%= @raft.description %></p>
              </div>
            <% end %>

            <%= if @raft.forum_url do %>
              <div class="mt-4">
                <p class="text-sm font-medium text-base-content/60">Lien forum</p>
                <a href={@raft.forum_url} target="_blank" class="link link-primary">
                  <%= @raft.forum_url %>
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
              Équipage
              <span class="badge badge-ghost"><%= length(@raft.crew.crew_members) %></span>
            </h3>

            <ul class="space-y-3 mt-2">
              <%= for member <- @raft.crew.crew_members do %>
                <li class="flex items-center justify-between">
                  <div>
                    <p class="font-medium"><%= Accounts.display_name(member.user) %></p>
                    <div class="flex flex-wrap gap-1 mt-1">
                      <%= if member.is_captain do %>
                        <span class="badge badge-primary badge-xs">Capitaine</span>
                      <% end %>
                      <%= if member.is_manager do %>
                        <span class="badge badge-secondary badge-xs">Gestionnaire</span>
                      <% end %>
                      <%= for role <- member.roles || [] do %>
                        <span class="badge badge-ghost badge-xs"><%= role %></span>
                      <% end %>
                    </div>
                  </div>
                </li>
              <% end %>
            </ul>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
