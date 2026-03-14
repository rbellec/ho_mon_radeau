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
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-6xl mx-auto">
        <.header>
          Fiches d'inscription
          <:subtitle>
            Édition {@edition.year} - {@pending_count} fiche(s) en attente
          </:subtitle>
          <:actions>
            <div class="flex gap-2">
              <button
                phx-click="set-view"
                phx-value-mode="list"
                class={[
                  "rounded-lg px-3 py-1.5 text-sm font-medium transition",
                  @view_mode == :list && "bg-indigo-600 text-white hover:bg-indigo-700"
                ]}
              >
                <.icon name="hero-list-bullet" class="size-4" /> Liste
              </button>
              <button
                phx-click="set-view"
                phx-value-mode="raft"
                class={[
                  "rounded-lg px-3 py-1.5 text-sm font-medium transition",
                  @view_mode == :raft && "bg-indigo-600 text-white hover:bg-indigo-700"
                ]}
              >
                <.icon name="hero-squares-2x2" class="size-4" /> Par radeau
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
    </Layouts.app>
    """
  end

  defp list_view(assigns) do
    ~H"""
    <div class="mt-6">
      <div class="flex gap-2 mb-4">
        <button
          phx-click="filter"
          phx-value-status=""
          class={[
            "rounded-lg px-3 py-1.5 text-sm font-medium transition",
            is_nil(@filter_status) && "bg-indigo-600 text-white hover:bg-indigo-700"
          ]}
        >
          Toutes
        </button>
        <button
          phx-click="filter"
          phx-value-status="pending"
          class={[
            "rounded-lg px-3 py-1.5 text-sm font-medium transition",
            @filter_status == "pending" && "bg-indigo-600 text-white hover:bg-indigo-700"
          ]}
        >
          En attente
        </button>
        <button
          phx-click="filter"
          phx-value-status="approved"
          class={[
            "rounded-lg px-3 py-1.5 text-sm font-medium transition",
            @filter_status == "approved" && "bg-indigo-600 text-white hover:bg-indigo-700"
          ]}
        >
          Validées
        </button>
        <button
          phx-click="filter"
          phx-value-status="rejected"
          class={[
            "rounded-lg px-3 py-1.5 text-sm font-medium transition",
            @filter_status == "rejected" && "bg-indigo-600 text-white hover:bg-indigo-700"
          ]}
        >
          Rejetées
        </button>
      </div>

      <%= if @forms == [] do %>
        <div class="bg-slate-50 border border-slate-200 text-slate-600 rounded-xl p-4 flex items-start gap-3">
          <.icon name="hero-inbox" class="size-6" />
          <span>Aucune fiche trouvée</span>
        </div>
      <% else %>
        <.table id="forms" rows={@forms}>
          <:col :let={form} label="Participant">
            <div class="flex items-center gap-2">
              <div>
                <div class="bg-slate-100 text-slate-600 rounded-full w-8 h-8 flex items-center justify-center">
                  <span class="text-xs">
                    {String.first(form.user.nickname || form.user.email) |> String.upcase()}
                  </span>
                </div>
              </div>
              <div>
                <div class="font-medium">{form.user.nickname || "Sans pseudo"}</div>
                <div class="text-xs text-slate-500">{form.user.email}</div>
              </div>
            </div>
          </:col>
          <:col :let={form} label="Type">
            <span class={[
              "text-xs font-medium px-2.5 py-0.5 rounded-full",
              form.form_type == "captain" && "bg-amber-100 text-amber-700",
              form.form_type == "participant" && "bg-indigo-100 text-indigo-700"
            ]}>
              {if form.form_type == "captain", do: "Capitaine", else: "Participant"}
            </span>
          </:col>
          <:col :let={form} label="Statut">
            <.status_badge status={form.status} />
          </:col>
          <:col :let={form} label="Envoyée le">
            {Calendar.strftime(form.uploaded_at, "%d/%m/%Y %H:%M")}
          </:col>
          <:action :let={form}>
            <.link
              navigate={~p"/admin/fiches/#{form.id}"}
              class="text-sm text-slate-600 hover:bg-slate-50 rounded-lg px-3 py-1.5 font-medium transition"
            >
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
        <div class="bg-slate-50 border border-slate-200 text-slate-600 rounded-xl p-4 flex items-start gap-3">
          <.icon name="hero-inbox" class="size-6" />
          <span>Aucun radeau trouvé</span>
        </div>
      <% else %>
        <div class="overflow-x-auto">
          <table class="w-full text-left">
            <thead>
              <tr>
                <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-3 py-2">
                  Radeau
                </th>
                <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-3 py-2 text-center">
                  Membres
                </th>
                <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-3 py-2 text-center">
                  Validées
                </th>
                <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-3 py-2 text-center">
                  En attente
                </th>
                <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-3 py-2 text-center">
                  Rejetées
                </th>
                <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-3 py-2 text-center">
                  Manquantes
                </th>
                <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-3 py-2"></th>
              </tr>
            </thead>
            <tbody>
              <%= for stat <- @stats do %>
                <tr class="border-b border-slate-100 hover:bg-slate-50">
                  <td class="px-3 py-2 text-sm font-medium">{stat.raft_name}</td>
                  <td class="px-3 py-2 text-sm text-center">{stat.total_members}</td>
                  <td class="px-3 py-2 text-sm text-center">
                    <span class="bg-green-100 text-green-700 text-xs font-medium px-2.5 py-0.5 rounded-full">
                      {stat.approved}
                    </span>
                  </td>
                  <td class="px-3 py-2 text-sm text-center">
                    <span class={[
                      "text-xs font-medium px-2.5 py-0.5 rounded-full",
                      if(stat.pending > 0,
                        do: "bg-indigo-100 text-indigo-700",
                        else: "bg-slate-100 text-slate-600"
                      )
                    ]}>
                      {stat.pending}
                    </span>
                  </td>
                  <td class="px-3 py-2 text-sm text-center">
                    <span class={[
                      "text-xs font-medium px-2.5 py-0.5 rounded-full",
                      if(stat.rejected > 0,
                        do: "bg-red-100 text-red-700",
                        else: "bg-slate-100 text-slate-600"
                      )
                    ]}>
                      {stat.rejected}
                    </span>
                  </td>
                  <td class="px-3 py-2 text-sm text-center">
                    <span class={[
                      "text-xs font-medium px-2.5 py-0.5 rounded-full",
                      if(stat.missing > 0,
                        do: "bg-amber-100 text-amber-700",
                        else: "bg-slate-100 text-slate-600"
                      )
                    ]}>
                      {stat.missing}
                    </span>
                  </td>
                  <td class="px-3 py-2 text-sm">
                    <%= if stat.missing > 0 || stat.rejected > 0 do %>
                      <button
                        phx-click="send-reminder"
                        phx-value-raft-id={stat.raft_id}
                        class="text-sm text-slate-600 hover:bg-slate-50 rounded-lg px-3 py-1.5 font-medium transition"
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
      "text-xs font-medium px-2.5 py-0.5 rounded-full",
      @status == "pending" && "bg-indigo-100 text-indigo-700",
      @status == "approved" && "bg-green-100 text-green-700",
      @status == "rejected" && "bg-red-100 text-red-700"
    ]}>
      {case @status do
        "pending" -> "En attente"
        "approved" -> "Validée"
        "rejected" -> "Rejetée"
      end}
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
