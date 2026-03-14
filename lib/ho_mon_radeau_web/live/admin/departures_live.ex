defmodule HoMonRadeauWeb.Admin.DeparturesLive do
  use HoMonRadeauWeb, :live_view

  alias HoMonRadeau.Events
  alias HoMonRadeau.Accounts

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Suivi des départs")
     |> assign(:filter_cuf, "all")
     |> load_departures()}
  end

  @impl true
  def handle_event("filter", %{"cuf_status" => status}, socket) do
    {:noreply,
     socket
     |> assign(:filter_cuf, status)
     |> load_departures()}
  end

  defp load_departures(socket) do
    filters = %{"cuf_status" => socket.assigns.filter_cuf}
    assign(socket, :departures, Events.list_crew_departures(filters))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Suivi des départs
        <:subtitle>{length(@departures)} départ{if length(@departures) != 1, do: "s"}</:subtitle>
      </.header>

      <div class="mt-6">
        <div class="flex gap-2 mb-4">
          <button
            class={["btn btn-sm", if(@filter_cuf == "all", do: "btn-primary", else: "btn-ghost")]}
            phx-click="filter"
            phx-value-cuf_status="all"
          >
            Tous
          </button>
          <button
            class={[
              "btn btn-sm",
              if(@filter_cuf == "validated", do: "btn-warning", else: "btn-ghost")
            ]}
            phx-click="filter"
            phx-value-cuf_status="validated"
          >
            CUF validée
          </button>
          <button
            class={[
              "btn btn-sm",
              if(@filter_cuf == "none", do: "btn-ghost btn-active", else: "btn-ghost")
            ]}
            phx-click="filter"
            phx-value-cuf_status="none"
          >
            Sans CUF
          </button>
        </div>

        <div class="overflow-x-auto">
          <table class="table table-sm" id="departures-table">
            <thead>
              <tr>
                <th>Membre</th>
                <th>Équipage</th>
                <th>Date</th>
                <th>CUF au départ</th>
                <th>Rôles</th>
                <th>Type</th>
              </tr>
            </thead>
            <tbody>
              <%= for dep <- @departures do %>
                <tr id={"departure-#{dep.id}"}>
                  <td>
                    <%= if dep.user do %>
                      {Accounts.display_name(dep.user)}
                    <% else %>
                      <span class="text-base-content/50">Utilisateur supprimé</span>
                    <% end %>
                  </td>
                  <td>
                    <%= if dep.crew && dep.crew.raft do %>
                      {dep.crew.raft.name}
                    <% else %>
                      <span class="text-base-content/50">—</span>
                    <% end %>
                  </td>
                  <td>{Calendar.strftime(dep.inserted_at, "%d/%m/%Y")}</td>
                  <td>
                    <%= case dep.cuf_status_at_departure do %>
                      <% "validated" -> %>
                        <span class="badge badge-warning badge-sm">CUF validée</span>
                      <% "declared" -> %>
                        <span class="badge badge-info badge-sm">CUF déclarée</span>
                      <% _ -> %>
                        <span class="text-base-content/50">—</span>
                    <% end %>
                  </td>
                  <td>
                    <div class="flex gap-1">
                      <%= if dep.was_captain do %>
                        <span class="badge badge-primary badge-xs">Capitaine</span>
                      <% end %>
                      <%= if dep.was_manager do %>
                        <span class="badge badge-secondary badge-xs">Gestionnaire</span>
                      <% end %>
                    </div>
                  </td>
                  <td>
                    <%= if dep.removed_by_id do %>
                      <span class="text-xs">Retiré</span>
                    <% else %>
                      <span class="text-xs">Volontaire</span>
                    <% end %>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
