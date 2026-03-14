defmodule HoMonRadeauWeb.Admin.UserLive.Index do
  use HoMonRadeauWeb, :live_view

  alias HoMonRadeau.Accounts

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Gestion des utilisateurs")
     |> assign(:filter, "all")
     |> assign(:search, "")
     |> load_users("all")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    filter = params["filter"] || "all"

    {:noreply,
     socket
     |> assign(:filter, filter)
     |> load_users(filter)}
  end

  @impl true
  def handle_event("filter", %{"filter" => filter}, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/utilisateurs?filter=#{filter}")}
  end

  @impl true
  def handle_event("validate", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)

    case Accounts.validate_user(user) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "#{Accounts.display_name(user)} a été validé·e.")
         |> load_users(socket.assigns.filter)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de la validation.")}
    end
  end

  @impl true
  def handle_event("invalidate", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)

    case Accounts.invalidate_user(user) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Validation de #{Accounts.display_name(user)} révoquée.")
         |> load_users(socket.assigns.filter)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de la révocation.")}
    end
  end

  defp load_users(socket, "pending") do
    assign(socket, :users, Accounts.list_pending_validation_users())
  end

  defp load_users(socket, "validated") do
    assign(socket, :users, Accounts.list_validated_users())
  end

  defp load_users(socket, _all) do
    assign(socket, :users, Accounts.list_all_users())
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Gestion des utilisateurs
      <:subtitle><%= length(@users) %> utilisateur<%= if length(@users) > 1, do: "s" %></:subtitle>
    </.header>

    <div class="mt-6">
      <div class="tabs tabs-boxed mb-4">
        <button
          class={"tab #{if @filter == "all", do: "tab-active"}"}
          phx-click="filter"
          phx-value-filter="all"
        >
          Tous
        </button>
        <button
          class={"tab #{if @filter == "pending", do: "tab-active"}"}
          phx-click="filter"
          phx-value-filter="pending"
        >
          En attente
        </button>
        <button
          class={"tab #{if @filter == "validated", do: "tab-active"}"}
          phx-click="filter"
          phx-value-filter="validated"
        >
          Validés
        </button>
      </div>

      <div class="overflow-x-auto">
        <table class="table table-zebra">
          <thead>
            <tr>
              <th>Pseudo</th>
              <th>Email</th>
              <th>Nom</th>
              <th>Inscrit·e le</th>
              <th>Statut</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <%= for user <- @users do %>
              <tr class="hover cursor-pointer" phx-click={JS.navigate(~p"/admin/utilisateurs/#{user.id}")}>
                <td class="font-medium">
                  <%= Accounts.display_name(user) %>
                </td>
                <td><%= user.email %></td>
                <td>
                  <%= if user.first_name || user.last_name do %>
                    <%= user.first_name %> <%= user.last_name %>
                  <% else %>
                    <span class="text-base-content/50">—</span>
                  <% end %>
                </td>
                <td>
                  <%= Calendar.strftime(user.inserted_at, "%d/%m/%Y") %>
                </td>
                <td>
                  <%= if user.validated do %>
                    <span class="badge badge-success">Validé·e</span>
                  <% else %>
                    <span class="badge badge-warning">En attente</span>
                  <% end %>
                  <%= if user.is_admin do %>
                    <span class="badge badge-info">Admin</span>
                  <% end %>
                </td>
                <td>
                  <%= if user.validated do %>
                    <button
                      class="btn btn-sm btn-ghost text-error"
                      phx-click="invalidate"
                      phx-value-id={user.id}
                    >
                      Révoquer
                    </button>
                  <% else %>
                    <button
                      class="btn btn-sm btn-primary"
                      phx-click="validate"
                      phx-value-id={user.id}
                    >
                      Valider
                    </button>
                  <% end %>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>

        <%= if Enum.empty?(@users) do %>
          <div class="text-center py-8 text-base-content/60">
            <%= case @filter do %>
              <% "pending" -> %>
                Aucun utilisateur en attente de validation.
              <% "validated" -> %>
                Aucun utilisateur validé.
              <% _ -> %>
                Aucun utilisateur.
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
