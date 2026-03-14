defmodule HoMonRadeauWeb.Admin.RaftLive.Index do
  use HoMonRadeauWeb, :live_view

  alias HoMonRadeau.Events

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Gestion des radeaux")
     |> assign(:filter_status, "all")
     |> assign(:filter_name, "")
     |> load_rafts()}
  end

  @impl true
  def handle_event("filter", %{"status" => status, "name" => name}, socket) do
    {:noreply,
     socket
     |> assign(:filter_status, status)
     |> assign(:filter_name, name)
     |> load_rafts()}
  end

  @impl true
  def handle_event("validate_raft", %{"id" => id}, socket) do
    raft = Events.get_raft!(id)
    admin = socket.assigns.current_scope.user

    case Events.validate_raft(raft, admin) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Radeau \"#{raft.name}\" validé.")
         |> load_rafts()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de la validation.")}
    end
  end

  @impl true
  def handle_event("invalidate_raft", %{"id" => id}, socket) do
    raft = Events.get_raft!(id)

    case Events.invalidate_raft(raft) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Radeau \"#{raft.name}\" invalidé.")
         |> load_rafts()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de l'invalidation.")}
    end
  end

  defp load_rafts(socket) do
    status_filter =
      case socket.assigns.filter_status do
        "all" -> nil
        status -> status
      end

    name_filter =
      case socket.assigns.filter_name do
        "" -> nil
        name -> name
      end

    filters = %{"status" => status_filter, "name" => name_filter}
    assign(socket, :rafts, Events.list_admin_rafts(filters))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Gestion des radeaux
        <:subtitle>{length(@rafts)} radeau{if length(@rafts) != 1, do: "x"}</:subtitle>
      </.header>

      <div class="mt-6">
        <form phx-change="filter" id="raft-filters" class="flex flex-wrap gap-4 items-end">
          <div class="mb-3">
            <label class="block text-sm font-medium text-slate-700 mb-1">Recherche</label>
            <input
              type="text"
              name="name"
              value={@filter_name}
              placeholder="Nom du radeau..."
              class="w-full rounded-lg border border-slate-300 px-3 py-1.5 text-sm focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 w-48"
              phx-debounce="300"
            />
          </div>
          <div class="mb-3">
            <label class="block text-sm font-medium text-slate-700 mb-1">Statut</label>
            <select
              name="status"
              class="rounded-lg border border-slate-300 px-3 py-1.5 text-sm focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 bg-white"
            >
              <option value="all" selected={@filter_status == "all"}>Tous</option>
              <option value="validated" selected={@filter_status == "validated"}>
                Participants
              </option>
              <option value="proposed" selected={@filter_status == "proposed"}>Proposés</option>
            </select>
          </div>
        </form>
      </div>

      <div class="mt-6 overflow-x-auto">
        <table class="w-full text-left" id="admin-rafts-table">
          <thead>
            <tr>
              <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-3 py-2">Nom</th>
              <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-3 py-2">
                Statut
              </th>
              <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-3 py-2">
                Membres
              </th>
              <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-3 py-2">
                Capitaine
              </th>
              <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-3 py-2">
                Créé le
              </th>
              <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-3 py-2">
                Actions
              </th>
            </tr>
          </thead>
          <tbody>
            <%= for entry <- @rafts do %>
              <tr id={"raft-#{entry.raft.id}"} class="border-b border-slate-100 hover:bg-slate-50">
                <td class="px-3 py-2 text-sm">
                  <.link
                    navigate={~p"/radeaux/#{entry.raft.slug}"}
                    class="text-indigo-600 hover:underline"
                  >
                    {entry.raft.name}
                  </.link>
                </td>
                <td class="px-3 py-2 text-sm">
                  <%= if entry.raft.validated do %>
                    <span class="bg-green-100 text-green-700 text-xs font-medium px-2 py-0.5 rounded-full">
                      Participant
                    </span>
                  <% else %>
                    <span class="bg-slate-100 text-slate-600 text-xs font-medium px-2 py-0.5 rounded-full">
                      Proposé
                    </span>
                  <% end %>
                </td>
                <td class="px-3 py-2 text-sm">{entry.member_count}</td>
                <td class="px-3 py-2 text-sm">{entry.captain_name || "—"}</td>
                <td class="px-3 py-2 text-sm">
                  {Calendar.strftime(entry.raft.inserted_at, "%d/%m/%Y")}
                </td>
                <td class="px-3 py-2 text-sm">
                  <%= if entry.raft.validated do %>
                    <button
                      class="text-xs text-slate-600 hover:bg-slate-50 rounded-md px-2 py-1 font-medium transition"
                      phx-click="invalidate_raft"
                      phx-value-id={entry.raft.id}
                      data-confirm={"Invalider le radeau \"#{entry.raft.name}\" ?"}
                    >
                      Invalider
                    </button>
                  <% else %>
                    <button
                      class="bg-green-600 text-white rounded-md px-2 py-1 text-xs font-medium hover:bg-green-700 transition"
                      phx-click="validate_raft"
                      phx-value-id={entry.raft.id}
                      data-confirm={"Valider le radeau \"#{entry.raft.name}\" comme participant ?"}
                    >
                      Valider
                    </button>
                  <% end %>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </Layouts.app>
    """
  end
end
