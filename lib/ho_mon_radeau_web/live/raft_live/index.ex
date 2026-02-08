defmodule HoMonRadeauWeb.RaftLive.Index do
  use HoMonRadeauWeb, :live_view

  alias HoMonRadeau.Events

  @impl true
  def mount(_params, _session, socket) do
    edition = Events.get_current_edition()

    rafts =
      if edition do
        Events.list_rafts(edition.id)
      else
        []
      end

    {:ok,
     socket
     |> assign(:page_title, "Les radeaux")
     |> assign(:edition, edition)
     |> assign(:rafts, rafts)
     |> assign_user_crew()}
  end

  defp assign_user_crew(socket) do
    case socket.assigns[:current_scope] do
      %{user: user} ->
        assign(socket, :user_crew, Events.get_user_crew(user))

      _ ->
        assign(socket, :user_crew, nil)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Les radeaux
      <:subtitle>
        <%= if @edition do %>
          Édition <%= @edition.name %>
        <% else %>
          Aucune édition en cours
        <% end %>
      </:subtitle>
      <:actions>
        <%= if @current_scope && @current_scope.user.validated && is_nil(@user_crew) do %>
          <.link navigate={~p"/radeaux/nouveau"} class="btn btn-primary">
            Créer un radeau
          </.link>
        <% end %>
      </:actions>
    </.header>

    <div class="mt-8">
      <%= if @current_scope && !@current_scope.user.validated do %>
        <div class="alert alert-warning mb-6">
          <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
          </svg>
          <span>
            Votre compte doit être validé par l'équipe d'accueil avant de pouvoir rejoindre un radeau.
          </span>
        </div>
      <% end %>

      <%= if @user_crew do %>
        <div class="alert alert-info mb-6">
          <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <span>
            Vous êtes membre d'un équipage.
            <.link navigate={~p"/mon-radeau"} class="link">Voir mon radeau</.link>
          </span>
        </div>
      <% end %>

      <%= if Enum.empty?(@rafts) do %>
        <div class="text-center py-12 text-base-content/60">
          <p class="text-xl mb-4">Aucun radeau pour le moment</p>
          <%= if @current_scope && @current_scope.user.validated && is_nil(@user_crew) do %>
            <p>Soyez le premier à créer un radeau !</p>
            <.link navigate={~p"/radeaux/nouveau"} class="btn btn-primary mt-4">
              Créer un radeau
            </.link>
          <% end %>
        </div>
      <% else %>
        <div class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          <%= for raft <- @rafts do %>
            <.link
              navigate={~p"/radeaux/#{raft.slug}"}
              class="card bg-base-200 hover:bg-base-300 transition-colors"
            >
              <div class="card-body">
                <h2 class="card-title">
                  <%= raft.name %>
                  <%= if raft.validated do %>
                    <span class="badge badge-success badge-sm">Validé</span>
                  <% end %>
                </h2>
                <%= if raft.description_short do %>
                  <p class="text-base-content/70"><%= raft.description_short %></p>
                <% end %>
                <div class="card-actions justify-end mt-2">
                  <span class="text-sm text-base-content/50">
                    <%= raft.crew_count %> membre<%= if raft.crew_count > 1, do: "s" %>
                  </span>
                </div>
              </div>
            </.link>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end
end
