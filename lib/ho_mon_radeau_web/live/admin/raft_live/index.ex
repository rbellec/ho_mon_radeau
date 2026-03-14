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
          <div class="form-control">
            <label class="label"><span class="label-text">Recherche</span></label>
            <input
              type="text"
              name="name"
              value={@filter_name}
              placeholder="Nom du radeau..."
              class="input input-bordered input-sm w-48"
              phx-debounce="300"
            />
          </div>
          <div class="form-control">
            <label class="label"><span class="label-text">Statut</span></label>
            <select name="status" class="select select-bordered select-sm">
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
        <table class="table table-sm" id="admin-rafts-table">
          <thead>
            <tr>
              <th>Nom</th>
              <th>Statut</th>
              <th>Membres</th>
              <th>Capitaine</th>
              <th>Créé le</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <%= for entry <- @rafts do %>
              <tr id={"raft-#{entry.raft.id}"}>
                <td>
                  <.link navigate={~p"/radeaux/#{entry.raft.slug}"} class="link link-primary">
                    {entry.raft.name}
                  </.link>
                </td>
                <td>
                  <%= if entry.raft.validated do %>
                    <span class="badge badge-success badge-sm">Participant</span>
                  <% else %>
                    <span class="badge badge-ghost badge-sm">Proposé</span>
                  <% end %>
                </td>
                <td>{entry.member_count}</td>
                <td>{entry.captain_name || "—"}</td>
                <td>{Calendar.strftime(entry.raft.inserted_at, "%d/%m/%Y")}</td>
                <td>
                  <%= if entry.raft.validated do %>
                    <button
                      class="btn btn-ghost btn-xs"
                      phx-click="invalidate_raft"
                      phx-value-id={entry.raft.id}
                      data-confirm={"Invalider le radeau \"#{entry.raft.name}\" ?"}
                    >
                      Invalider
                    </button>
                  <% else %>
                    <button
                      class="btn btn-success btn-xs"
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
