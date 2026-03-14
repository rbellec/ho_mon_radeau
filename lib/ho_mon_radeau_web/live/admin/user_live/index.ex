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
      <:subtitle>{length(@users)} utilisateur{if length(@users) > 1, do: "s"}</:subtitle>
    </.header>

    <div class="mt-6">
      <div class="flex gap-1 bg-slate-100 rounded-lg p-1 mb-4">
        <button
          class={"px-3 py-1.5 text-sm font-medium rounded-md transition #{if @filter == "all", do: "bg-white text-indigo-600 shadow-sm", else: "text-slate-600 hover:text-slate-900"}"}
          phx-click="filter"
          phx-value-filter="all"
        >
          Tous
        </button>
        <button
          class={"px-3 py-1.5 text-sm font-medium rounded-md transition #{if @filter == "pending", do: "bg-white text-indigo-600 shadow-sm", else: "text-slate-600 hover:text-slate-900"}"}
          phx-click="filter"
          phx-value-filter="pending"
        >
          En attente
        </button>
        <button
          class={"px-3 py-1.5 text-sm font-medium rounded-md transition #{if @filter == "validated", do: "bg-white text-indigo-600 shadow-sm", else: "text-slate-600 hover:text-slate-900"}"}
          phx-click="filter"
          phx-value-filter="validated"
        >
          Validés
        </button>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full text-left">
          <thead>
            <tr>
              <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-4 py-3">
                Pseudo
              </th>
              <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-4 py-3">
                Email
              </th>
              <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-4 py-3">Nom</th>
              <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-4 py-3">
                Inscrit·e le
              </th>
              <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-4 py-3">
                Statut
              </th>
              <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-4 py-3">
                Actions
              </th>
            </tr>
          </thead>
          <tbody>
            <%= for user <- @users do %>
              <tr
                class="border-b border-slate-100 hover:bg-slate-50 cursor-pointer"
                phx-click={JS.navigate(~p"/admin/utilisateurs/#{user.id}")}
              >
                <td class="px-4 py-3 text-sm font-medium">
                  {Accounts.display_name(user)}
                </td>
                <td class="px-4 py-3 text-sm">{user.email}</td>
                <td class="px-4 py-3 text-sm">
                  <%= if user.first_name || user.last_name do %>
                    {user.first_name} {user.last_name}
                  <% else %>
                    <span class="text-slate-400">—</span>
                  <% end %>
                </td>
                <td class="px-4 py-3 text-sm">
                  {Calendar.strftime(user.inserted_at, "%d/%m/%Y")}
                </td>
                <td class="px-4 py-3 text-sm">
                  <%= if user.validated do %>
                    <span class="bg-green-100 text-green-700 text-xs font-medium px-2.5 py-0.5 rounded-full">
                      Validé·e
                    </span>
                  <% else %>
                    <span class="bg-amber-100 text-amber-700 text-xs font-medium px-2.5 py-0.5 rounded-full">
                      En attente
                    </span>
                  <% end %>
                  <%= if user.is_admin do %>
                    <span class="bg-indigo-100 text-indigo-700 text-xs font-medium px-2.5 py-0.5 rounded-full">
                      Admin
                    </span>
                  <% end %>
                </td>
                <td class="px-4 py-3 text-sm">
                  <%= if user.validated do %>
                    <button
                      class="text-sm text-red-600 hover:bg-red-50 rounded-lg px-3 py-1.5 font-medium transition"
                      phx-click="invalidate"
                      phx-value-id={user.id}
                    >
                      Révoquer
                    </button>
                  <% else %>
                    <button
                      class="bg-indigo-600 text-white rounded-lg px-3 py-1.5 text-sm font-medium hover:bg-indigo-700 transition"
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
          <div class="text-center py-8 text-slate-400">
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
