defmodule HoMonRadeauWeb.Admin.CUFLive.Index do
  use HoMonRadeauWeb, :live_view

  alias HoMonRadeau.CUF

  @impl true
  def mount(_params, _session, socket) do
    settings = CUF.get_settings()
    stats = CUF.get_participant_stats()

    {:ok,
     socket
     |> assign(:page_title, "Gestion CUF")
     |> assign(:filter_status, "all")
     |> assign(:settings, settings)
     |> assign(:stats, stats)
     |> assign(:settings_form, to_form(CUF.change_settings(settings)))
     |> load_declarations()}
  end

  @impl true
  def handle_event("filter", %{"status" => status}, socket) do
    {:noreply,
     socket
     |> assign(:filter_status, status)
     |> load_declarations()}
  end

  @impl true
  def handle_event("validate_declaration", %{"id" => id}, socket) do
    declaration = CUF.get_declaration!(id)
    admin = socket.assigns.current_scope.user

    case CUF.validate_declaration(declaration, admin.id) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "CUF validée pour #{declaration.crew.raft.name}.")
         |> assign(:stats, CUF.get_participant_stats())
         |> load_declarations()}

      {:error, _, _, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de la validation.")}
    end
  end

  @impl true
  def handle_event("update_settings", %{"cuf_settings" => params}, socket) do
    case CUF.update_settings(params) do
      {:ok, settings} ->
        {:noreply,
         socket
         |> assign(:settings, settings)
         |> assign(:settings_form, to_form(CUF.change_settings(settings)))
         |> put_flash(:info, "Configuration CUF mise à jour.")}

      {:error, changeset} ->
        {:noreply, assign(socket, :settings_form, to_form(changeset))}
    end
  end

  defp load_declarations(socket) do
    status =
      case socket.assigns.filter_status do
        "all" -> nil
        s -> s
      end

    assign(socket, :declarations, CUF.list_all_declarations(status))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Gestion CUF
        <:subtitle>Cotisation Urbaine Flottante</:subtitle>
      </.header>

      <%!-- Stats --%>
      <div class="grid grid-cols-2 md:grid-cols-3 gap-4 mt-6" id="cuf-stats">
        <div class="stat bg-base-200 rounded-lg p-4">
          <div class="stat-title text-xs">Participants validés</div>
          <div class="stat-value text-lg">
            {@stats.validated}
            <%= if @stats.limit do %>
              <span class="text-sm font-normal text-base-content/50">/ {@stats.limit}</span>
            <% end %>
          </div>
        </div>
        <div class="stat bg-base-200 rounded-lg p-4">
          <div class="stat-title text-xs">Montant CUF / personne</div>
          <div class="stat-value text-lg">{@settings.unit_price} €</div>
        </div>
        <div class="stat bg-base-200 rounded-lg p-4">
          <div class="stat-title text-xs">Déclarations</div>
          <div class="stat-value text-lg">{length(@declarations)}</div>
        </div>
      </div>

      <%!-- Settings --%>
      <details class="mt-6">
        <summary class="cursor-pointer font-medium">Configuration</summary>
        <div class="card bg-base-200 mt-2">
          <div class="card-body">
            <.form for={@settings_form} id="cuf-settings-form" phx-submit="update_settings">
              <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-4">
                <.input
                  field={@settings_form[:unit_price]}
                  type="number"
                  label="Montant CUF (€)"
                  step="0.01"
                />
                <.input
                  field={@settings_form[:total_limit]}
                  type="number"
                  label="Limite participants"
                />
                <.input field={@settings_form[:rib_iban]} type="text" label="IBAN" />
                <.input field={@settings_form[:rib_bic]} type="text" label="BIC" />
              </div>
              <div class="mt-4">
                <.button variant="primary" phx-disable-with="Enregistrement...">
                  Enregistrer
                </.button>
              </div>
            </.form>
          </div>
        </div>
      </details>

      <%!-- Declarations list --%>
      <div class="mt-6">
        <div class="flex gap-2 mb-4">
          <button
            class={["btn btn-sm", if(@filter_status == "all", do: "btn-primary", else: "btn-ghost")]}
            phx-click="filter"
            phx-value-status="all"
          >
            Toutes
          </button>
          <button
            class={[
              "btn btn-sm",
              if(@filter_status == "pending", do: "btn-warning", else: "btn-ghost")
            ]}
            phx-click="filter"
            phx-value-status="pending"
          >
            En attente
          </button>
          <button
            class={[
              "btn btn-sm",
              if(@filter_status == "validated", do: "btn-success", else: "btn-ghost")
            ]}
            phx-click="filter"
            phx-value-status="validated"
          >
            Validées
          </button>
        </div>

        <div class="overflow-x-auto">
          <table class="table table-sm" id="cuf-declarations-table">
            <thead>
              <tr>
                <th>Radeau</th>
                <th>Participants</th>
                <th>Montant</th>
                <th>Statut</th>
                <th>Date</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <%= for decl <- @declarations do %>
                <tr id={"cuf-#{decl.id}"}>
                  <td class="font-medium">{decl.crew.raft.name}</td>
                  <td>{decl.participant_count}</td>
                  <td>{decl.total_amount} €</td>
                  <td>
                    <%= if decl.status == "validated" do %>
                      <span class="badge badge-success badge-sm">Validée</span>
                    <% else %>
                      <span class="badge badge-warning badge-sm">En attente</span>
                    <% end %>
                  </td>
                  <td>{Calendar.strftime(decl.inserted_at, "%d/%m/%Y")}</td>
                  <td>
                    <%= if decl.status == "pending" do %>
                      <button
                        class="btn btn-success btn-xs"
                        phx-click="validate_declaration"
                        phx-value-id={decl.id}
                        data-confirm={"Valider la CUF de #{decl.crew.raft.name} (#{decl.participant_count} participants, #{decl.total_amount} €) ?"}
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
      </div>
    </Layouts.app>
    """
  end
end
