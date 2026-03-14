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
            class={[
              if(@filter_cuf == "all",
                do:
                  "bg-indigo-600 text-white rounded-lg px-3 py-1.5 text-sm font-medium hover:bg-indigo-700 transition",
                else:
                  "text-sm text-slate-600 hover:bg-slate-50 rounded-lg px-3 py-1.5 font-medium transition"
              )
            ]}
            phx-click="filter"
            phx-value-cuf_status="all"
          >
            Tous
          </button>
          <button
            class={[
              if(@filter_cuf == "validated",
                do:
                  "bg-amber-500 text-white rounded-lg px-3 py-1.5 text-sm font-medium hover:bg-amber-600 transition",
                else:
                  "text-sm text-slate-600 hover:bg-slate-50 rounded-lg px-3 py-1.5 font-medium transition"
              )
            ]}
            phx-click="filter"
            phx-value-cuf_status="validated"
          >
            CUF validée
          </button>
          <button
            class={[
              if(@filter_cuf == "none",
                do: "bg-indigo-100 text-indigo-700 rounded-lg px-3 py-1.5 text-sm font-medium",
                else:
                  "text-sm text-slate-600 hover:bg-slate-50 rounded-lg px-3 py-1.5 font-medium transition"
              )
            ]}
            phx-click="filter"
            phx-value-cuf_status="none"
          >
            Sans CUF
          </button>
        </div>

        <div class="overflow-x-auto">
          <table class="w-full text-left" id="departures-table">
            <thead>
              <tr>
                <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-3 py-2">
                  Membre
                </th>
                <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-3 py-2">
                  Équipage
                </th>
                <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-3 py-2">
                  Date
                </th>
                <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-3 py-2">
                  CUF au départ
                </th>
                <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-3 py-2">
                  Rôles
                </th>
                <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-3 py-2">
                  Type
                </th>
              </tr>
            </thead>
            <tbody>
              <%= for dep <- @departures do %>
                <tr id={"departure-#{dep.id}"} class="border-b border-slate-100 hover:bg-slate-50">
                  <td class="px-3 py-2 text-sm">
                    <%= if dep.user do %>
                      {Accounts.display_name(dep.user)}
                    <% else %>
                      <span class="text-slate-400">Utilisateur supprimé</span>
                    <% end %>
                  </td>
                  <td class="px-3 py-2 text-sm">
                    <%= if dep.crew && dep.crew.raft do %>
                      {dep.crew.raft.name}
                    <% else %>
                      <span class="text-slate-400">—</span>
                    <% end %>
                  </td>
                  <td class="px-3 py-2 text-sm">{Calendar.strftime(dep.inserted_at, "%d/%m/%Y")}</td>
                  <td class="px-3 py-2 text-sm">
                    <%= case dep.cuf_status_at_departure do %>
                      <% "validated" -> %>
                        <span class="bg-amber-100 text-amber-700 text-xs font-medium px-2 py-0.5 rounded-full">
                          CUF validée
                        </span>
                      <% "declared" -> %>
                        <span class="bg-indigo-100 text-indigo-700 text-xs font-medium px-2 py-0.5 rounded-full">
                          CUF déclarée
                        </span>
                      <% _ -> %>
                        <span class="text-slate-400">—</span>
                    <% end %>
                  </td>
                  <td class="px-3 py-2 text-sm">
                    <div class="flex gap-1">
                      <%= if dep.was_captain do %>
                        <span class="bg-indigo-100 text-indigo-700 text-xs font-medium px-1.5 py-0.5 rounded-full">
                          Capitaine
                        </span>
                      <% end %>
                      <%= if dep.was_manager do %>
                        <span class="bg-indigo-100 text-indigo-600 text-xs font-medium px-1.5 py-0.5 rounded-full">
                          Gestionnaire
                        </span>
                      <% end %>
                    </div>
                  </td>
                  <td class="px-3 py-2 text-sm">
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
