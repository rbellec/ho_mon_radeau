defmodule HoMonRadeauWeb.Admin.RegistrationFormLive.Index do
  @moduledoc """
  Admin LiveView for managing registration forms.
  """
  use HoMonRadeauWeb, :live_view

  alias HoMonRadeau.Events

  @impl true
  def mount(_params, _session, socket) do
    edition = Events.get_current_edition()

    if edition do
      socket =
        socket
        |> assign(:edition, edition)
        |> assign(:page_title, "Admin - Fiches d'inscription")
        |> assign(:filter_status, nil)
        |> assign(:view_mode, :list)
        |> load_data()

      {:ok, socket}
    else
      {:ok,
       socket
       |> put_flash(:error, "Aucune édition en cours")
       |> redirect(to: ~p"/")}
    end
  end

  defp load_data(socket) do
    edition = socket.assigns.edition
    filter_status = socket.assigns.filter_status

    forms = Events.list_registration_forms(edition.id, status: filter_status)
    pending_count = Enum.count(forms, &(&1.status == "pending"))
    stats_by_raft = Events.registration_form_stats_by_raft(edition.id)

    socket
    |> assign(:forms, forms)
    |> assign(:pending_count, pending_count)
    |> assign(:stats_by_raft, stats_by_raft)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto">
      <.header>
        Fiches d'inscription
        <:subtitle>
          Édition <%= @edition.year %> - <%= @pending_count %> fiche(s) en attente
        </:subtitle>
        <:actions>
          <div class="flex gap-2">
            <button
              phx-click="set-view"
              phx-value-mode="list"
              class={["btn btn-sm", @view_mode == :list && "btn-primary"]}
            >
              <.icon name="hero-list-bullet" class="size-4" />
              Liste
            </button>
            <button
              phx-click="set-view"
              phx-value-mode="raft"
              class={["btn btn-sm", @view_mode == :raft && "btn-primary"]}
            >
              <.icon name="hero-squares-2x2" class="size-4" />
              Par radeau
            </button>
          </div>
        </:actions>
      </.header>

      <%= if @view_mode == :list do %>
        <.list_view forms={@forms} filter_status={@filter_status} />
      <% else %>
        <.raft_view stats={@stats_by_raft} edition={@edition} />
      <% end %>
    </div>
    """
  end

  defp list_view(assigns) do
    ~H"""
    <div class="mt-6">
      <div class="flex gap-2 mb-4">
        <button
          phx-click="filter"
          phx-value-status=""
          class={["btn btn-sm", is_nil(@filter_status) && "btn-primary"]}
        >
          Toutes
        </button>
        <button
          phx-click="filter"
          phx-value-status="pending"
          class={["btn btn-sm", @filter_status == "pending" && "btn-primary"]}
        >
          En attente
        </button>
        <button
          phx-click="filter"
          phx-value-status="approved"
          class={["btn btn-sm", @filter_status == "approved" && "btn-primary"]}
        >
          Validées
        </button>
        <button
          phx-click="filter"
          phx-value-status="rejected"
          class={["btn btn-sm", @filter_status == "rejected" && "btn-primary"]}
        >
          Rejetées
        </button>
      </div>

      <%= if @forms == [] do %>
        <div class="alert">
          <.icon name="hero-inbox" class="size-6" />
          <span>Aucune fiche trouvée</span>
        </div>
      <% else %>
        <.table id="forms" rows={@forms}>
          <:col :let={form} label="Participant">
            <div class="flex items-center gap-2">
              <div class="avatar placeholder">
                <div class="bg-base-300 text-base-content rounded-full w-8">
                  <span class="text-xs">
                    <%= String.first(form.user.nickname || form.user.email) |> String.upcase() %>
                  </span>
                </div>
              </div>
              <div>
                <div class="font-medium"><%= form.user.nickname || "Sans pseudo" %></div>
                <div class="text-xs text-base-content/70"><%= form.user.email %></div>
              </div>
            </div>
          </:col>
          <:col :let={form} label="Type">
            <span class={[
              "badge",
              form.form_type == "captain" && "badge-warning",
              form.form_type == "participant" && "badge-info"
            ]}>
              <%= if form.form_type == "captain", do: "Capitaine", else: "Participant" %>
            </span>
          </:col>
          <:col :let={form} label="Statut">
            <.status_badge status={form.status} />
          </:col>
          <:col :let={form} label="Envoyée le">
            <%= Calendar.strftime(form.uploaded_at, "%d/%m/%Y %H:%M") %>
          </:col>
          <:action :let={form}>
            <.link navigate={~p"/admin/fiches/#{form.id}"} class="btn btn-ghost btn-sm">
              <.icon name="hero-eye" class="size-4" />
            </.link>
          </:action>
        </.table>
      <% end %>
    </div>
    """
  end

  defp raft_view(assigns) do
    ~H"""
    <div class="mt-6">
      <%= if @stats == [] do %>
        <div class="alert">
          <.icon name="hero-inbox" class="size-6" />
          <span>Aucun radeau trouvé</span>
        </div>
      <% else %>
        <div class="overflow-x-auto">
          <table class="table table-zebra">
            <thead>
              <tr>
                <th>Radeau</th>
                <th class="text-center">Membres</th>
                <th class="text-center">Validées</th>
                <th class="text-center">En attente</th>
                <th class="text-center">Rejetées</th>
                <th class="text-center">Manquantes</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              <%= for stat <- @stats do %>
                <tr>
                  <td class="font-medium"><%= stat.raft_name %></td>
                  <td class="text-center"><%= stat.total_members %></td>
                  <td class="text-center">
                    <span class="badge badge-success"><%= stat.approved %></span>
                  </td>
                  <td class="text-center">
                    <span class={["badge", stat.pending > 0 && "badge-info"]}>
                      <%= stat.pending %>
                    </span>
                  </td>
                  <td class="text-center">
                    <span class={["badge", stat.rejected > 0 && "badge-error"]}>
                      <%= stat.rejected %>
                    </span>
                  </td>
                  <td class="text-center">
                    <span class={["badge", stat.missing > 0 && "badge-warning"]}>
                      <%= stat.missing %>
                    </span>
                  </td>
                  <td>
                    <%= if stat.missing > 0 || stat.rejected > 0 do %>
                      <button
                        phx-click="send-reminder"
                        phx-value-raft-id={stat.raft_id}
                        class="btn btn-ghost btn-sm"
                        title="Envoyer un rappel"
                      >
                        <.icon name="hero-envelope" class="size-4" />
                      </button>
                    <% end %>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% end %>
    </div>
    """
  end

  defp status_badge(assigns) do
    ~H"""
    <span class={[
      "badge",
      @status == "pending" && "badge-info",
      @status == "approved" && "badge-success",
      @status == "rejected" && "badge-error"
    ]}>
      <%= case @status do
        "pending" -> "En attente"
        "approved" -> "Validée"
        "rejected" -> "Rejetée"
      end %>
    </span>
    """
  end

  @impl true
  def handle_event("filter", %{"status" => ""}, socket) do
    {:noreply,
     socket
     |> assign(:filter_status, nil)
     |> load_data()}
  end

  def handle_event("filter", %{"status" => status}, socket) do
    {:noreply,
     socket
     |> assign(:filter_status, status)
     |> load_data()}
  end

  @impl true
  def handle_event("set-view", %{"mode" => mode}, socket) do
    {:noreply, assign(socket, :view_mode, String.to_atom(mode))}
  end

  @impl true
  def handle_event("send-reminder", %{"raft-id" => _raft_id}, socket) do
    # TODO: Implement reminder email sending
    {:noreply, put_flash(socket, :info, "Rappels envoyés (fonctionnalité à implémenter)")}
  end
end
