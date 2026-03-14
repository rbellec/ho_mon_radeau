defmodule HoMonRadeauWeb.Admin.DrumsLive.Index do
  use HoMonRadeauWeb, :live_view

  alias HoMonRadeau.Drums

  @impl true
  def mount(_params, _session, socket) do
    settings = Drums.get_settings()

    {:ok,
     socket
     |> assign(:page_title, "Gestion des bidons")
     |> assign(:filter_status, "all")
     |> assign(:settings, settings)
     |> assign(:settings_form, to_form(Drums.change_settings(settings)))
     |> load_requests()}
  end

  @impl true
  def handle_event("filter", %{"status" => status}, socket) do
    {:noreply,
     socket
     |> assign(:filter_status, status)
     |> load_requests()}
  end

  @impl true
  def handle_event("validate_payment", %{"id" => id}, socket) do
    request = Drums.get_request!(id)
    admin = socket.assigns.current_scope.user

    case Drums.validate_payment(request, admin.id) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Paiement validé pour #{request.crew.raft.name}.")
         |> load_requests()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de la validation.")}
    end
  end

  @impl true
  def handle_event("update_settings", %{"drum_settings" => params}, socket) do
    case Drums.update_settings(params) do
      {:ok, settings} ->
        {:noreply,
         socket
         |> assign(:settings, settings)
         |> assign(:settings_form, to_form(Drums.change_settings(settings)))
         |> put_flash(:info, "Configuration mise à jour.")}

      {:error, changeset} ->
        {:noreply, assign(socket, :settings_form, to_form(changeset))}
    end
  end

  defp load_requests(socket) do
    status =
      case socket.assigns.filter_status do
        "all" -> nil
        s -> s
      end

    requests = Drums.list_all_requests(status)

    paid = Enum.filter(requests, &(&1.status == "paid"))
    pending = Enum.filter(requests, &(&1.status == "pending"))

    stats = %{
      total_paid: Enum.reduce(paid, 0, fn r, acc -> acc + r.quantity end),
      total_paid_amount:
        Enum.reduce(paid, Decimal.new(0), fn r, acc -> Decimal.add(acc, r.total_amount) end),
      total_pending: Enum.reduce(pending, 0, fn r, acc -> acc + r.quantity end),
      total_pending_amount:
        Enum.reduce(pending, Decimal.new(0), fn r, acc -> Decimal.add(acc, r.total_amount) end)
    }

    socket
    |> assign(:requests, requests)
    |> assign(:stats, stats)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Gestion des bidons
        <:subtitle>{length(@requests)} demande{if length(@requests) != 1, do: "s"}</:subtitle>
      </.header>

      <%!-- Stats --%>
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mt-6" id="drums-stats">
        <div class="stat bg-base-200 rounded-lg p-4">
          <div class="stat-title text-xs">Bidons payés</div>
          <div class="stat-value text-lg">{@stats.total_paid}</div>
        </div>
        <div class="stat bg-base-200 rounded-lg p-4">
          <div class="stat-title text-xs">Montant payé</div>
          <div class="stat-value text-lg">{@stats.total_paid_amount} €</div>
        </div>
        <div class="stat bg-base-200 rounded-lg p-4">
          <div class="stat-title text-xs">Bidons en attente</div>
          <div class="stat-value text-lg">{@stats.total_pending}</div>
        </div>
        <div class="stat bg-base-200 rounded-lg p-4">
          <div class="stat-title text-xs">Montant en attente</div>
          <div class="stat-value text-lg">{@stats.total_pending_amount} €</div>
        </div>
      </div>

      <%!-- Settings --%>
      <details class="mt-6">
        <summary class="cursor-pointer font-medium">Configuration</summary>
        <div class="card bg-base-200 mt-2">
          <div class="card-body">
            <.form for={@settings_form} id="drum-settings-form" phx-submit="update_settings">
              <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <.input
                  field={@settings_form[:unit_price]}
                  type="number"
                  label="Tarif par bidon (€)"
                  step="0.01"
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

      <%!-- Filter and list --%>
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
            class={["btn btn-sm", if(@filter_status == "paid", do: "btn-success", else: "btn-ghost")]}
            phx-click="filter"
            phx-value-status="paid"
          >
            Payées
          </button>
        </div>

        <div class="overflow-x-auto">
          <table class="table table-sm" id="drums-requests-table">
            <thead>
              <tr>
                <th>Radeau</th>
                <th>Bidons</th>
                <th>Montant</th>
                <th>Statut</th>
                <th>Date</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <%= for request <- @requests do %>
                <tr id={"drum-#{request.id}"}>
                  <td class="font-medium">{request.crew.raft.name}</td>
                  <td>{request.quantity}</td>
                  <td>{request.total_amount} €</td>
                  <td>
                    <%= if request.status == "paid" do %>
                      <span class="badge badge-success badge-sm">Payé</span>
                    <% else %>
                      <span class="badge badge-warning badge-sm">En attente</span>
                    <% end %>
                  </td>
                  <td>{Calendar.strftime(request.inserted_at, "%d/%m/%Y")}</td>
                  <td>
                    <%= if request.status == "pending" do %>
                      <button
                        class="btn btn-success btn-xs"
                        phx-click="validate_payment"
                        phx-value-id={request.id}
                        data-confirm={"Valider le paiement de #{request.quantity} bidons (#{request.total_amount} €) pour #{request.crew.raft.name} ?"}
                      >
                        Valider paiement
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
