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
     |> assign(:view_mode, :grid)
     |> assign_user_context()}
  end

  @impl true
  def handle_event("toggle_view", %{"mode" => mode}, socket) do
    {:noreply, assign(socket, :view_mode, String.to_existing_atom(mode))}
  end

  defp assign_user_context(socket) do
    case socket.assigns.current_scope do
      %{user: user} ->
        user_crew = Events.get_user_crew(user)

        user_raft =
          if user_crew do
            Events.get_raft!(user_crew.raft_id)
          end

        socket
        |> assign(:user_crew, user_crew)
        |> assign(:user_raft, user_raft)

      _ ->
        socket
        |> assign(:user_crew, nil)
        |> assign(:user_raft, nil)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Les radeaux
        <:subtitle>
          <%= if @edition do %>
            Édition {@edition.name}
          <% else %>
            Aucune édition en cours
          <% end %>
        </:subtitle>
        <:actions>
          <%= if @current_scope && @current_scope.user.validated && is_nil(@user_crew) do %>
            <.link
              navigate={~p"/radeaux/nouveau"}
              class="bg-indigo-600 text-white rounded-lg px-5 py-2.5 font-medium hover:bg-indigo-700 transition inline-flex items-center"
            >
              Créer un radeau
            </.link>
          <% end %>
        </:actions>
      </.header>

      <div class="mt-8">
        <%= if @current_scope && !@current_scope.user.validated do %>
          <div class="bg-amber-50 border border-amber-200 text-amber-800 rounded-xl p-4 flex items-start gap-3 mb-6">
            <.icon name="hero-exclamation-triangle" class="size-6 shrink-0" />
            <span>
              Votre compte doit être validé par l'équipe d'accueil avant de pouvoir rejoindre un radeau.
            </span>
          </div>
        <% end %>

        <%= if @user_crew do %>
          <div class="bg-indigo-50 border border-indigo-200 text-indigo-800 rounded-xl p-4 flex items-start gap-3 mb-6">
            <.icon name="hero-information-circle" class="size-6" />
            <span>
              <%= if @user_raft do %>
                Votre radeau :
                <.link navigate={~p"/mon-radeau"} class="text-indigo-600 hover:underline font-medium">
                  {@user_raft.name}
                </.link>
              <% else %>
                <.link navigate={~p"/mon-radeau"} class="text-indigo-600 hover:underline">
                  Voir la page de votre radeau
                </.link>
              <% end %>
            </span>
          </div>
        <% end %>

        <%= if Enum.empty?(@rafts) do %>
          <div class="text-center py-12 text-slate-400">
            <p class="text-xl mb-4">Aucun radeau pour le moment</p>
            <%= if @current_scope && @current_scope.user.validated && is_nil(@user_crew) do %>
              <p>Soyez le premier à créer un radeau !</p>
              <.link
                navigate={~p"/radeaux/nouveau"}
                class="bg-indigo-600 text-white rounded-lg px-5 py-2.5 font-medium hover:bg-indigo-700 transition inline-flex items-center mt-4"
              >
                Créer un radeau
              </.link>
            <% end %>
          </div>
        <% else %>
          <%!-- View toggle --%>
          <div class="flex justify-end mb-4">
            <div class="inline-flex rounded-lg border border-slate-200 bg-white">
              <button
                phx-click="toggle_view"
                phx-value-mode="grid"
                class={[
                  "px-3 py-1.5 text-sm font-medium rounded-l-lg transition",
                  if(@view_mode == :grid,
                    do: "bg-indigo-600 text-white",
                    else: "text-slate-600 hover:bg-slate-50"
                  )
                ]}
              >
                <.icon name="hero-squares-2x2-mini" class="size-4" />
              </button>
              <button
                phx-click="toggle_view"
                phx-value-mode="list"
                class={[
                  "px-3 py-1.5 text-sm font-medium rounded-r-lg transition",
                  if(@view_mode == :list,
                    do: "bg-indigo-600 text-white",
                    else: "text-slate-600 hover:bg-slate-50"
                  )
                ]}
              >
                <.icon name="hero-bars-3-mini" class="size-4" />
              </button>
            </div>
          </div>

          <%= if @view_mode == :grid do %>
            <%!-- Grid view --%>
            <div class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
              <%= for raft <- @rafts do %>
                <.link
                  navigate={~p"/radeaux/#{raft.slug}"}
                  class="bg-white rounded-xl shadow-sm border border-slate-200 hover:shadow-md transition-shadow"
                >
                  <div class="p-6">
                    <h2 class="text-lg font-semibold text-slate-900">
                      {raft.name}
                      <%= if raft.validated do %>
                        <span class="bg-green-100 text-green-700 text-xs font-medium px-2.5 py-0.5 rounded-full inline-flex items-center">
                          Validé
                        </span>
                      <% end %>
                    </h2>
                    <%= if raft.description_short do %>
                      <p class="text-slate-500 mt-1">{raft.description_short}</p>
                    <% end %>
                    <div class="flex flex-wrap gap-2 justify-end mt-2">
                      <span class="text-sm text-slate-400">
                        {raft.crew_count} membre{if raft.crew_count > 1, do: "s"}
                      </span>
                    </div>
                  </div>
                </.link>
              <% end %>
            </div>
          <% else %>
            <%!-- List view --%>
            <div class="bg-white rounded-xl shadow-sm border border-slate-200 divide-y divide-slate-100">
              <%= for raft <- @rafts do %>
                <.link
                  navigate={~p"/radeaux/#{raft.slug}"}
                  class="flex items-center justify-between px-6 py-4 hover:bg-slate-50 transition-colors"
                >
                  <div class="min-w-0 flex-1">
                    <div class="flex items-center gap-2">
                      <h2 class="font-semibold text-slate-900 truncate">{raft.name}</h2>
                      <%= if raft.validated do %>
                        <span class="bg-green-100 text-green-700 text-xs font-medium px-2 py-0.5 rounded-full shrink-0">
                          Validé
                        </span>
                      <% end %>
                    </div>
                    <%= if raft.description_short do %>
                      <p class="text-sm text-slate-500 truncate mt-0.5">{raft.description_short}</p>
                    <% end %>
                  </div>
                  <span class="text-sm text-slate-400 shrink-0 ml-4">
                    {raft.crew_count} membre{if raft.crew_count > 1, do: "s"}
                  </span>
                </.link>
              <% end %>
            </div>
          <% end %>
        <% end %>
      </div>
    </Layouts.app>
    """
  end
end
