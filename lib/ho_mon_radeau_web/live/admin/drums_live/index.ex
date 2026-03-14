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
        <div class="bg-slate-50 rounded-lg p-4">
          <div class="text-xs text-slate-500 font-medium">Bidons payés</div>
          <div class="text-lg font-bold text-slate-900">{@stats.total_paid}</div>
        </div>
        <div class="bg-slate-50 rounded-lg p-4">
          <div class="text-xs text-slate-500 font-medium">Montant payé</div>
          <div class="text-lg font-bold text-slate-900">{@stats.total_paid_amount} €</div>
        </div>
        <div class="bg-slate-50 rounded-lg p-4">
          <div class="text-xs text-slate-500 font-medium">Bidons en attente</div>
          <div class="text-lg font-bold text-slate-900">{@stats.total_pending}</div>
        </div>
        <div class="bg-slate-50 rounded-lg p-4">
          <div class="text-xs text-slate-500 font-medium">Montant en attente</div>
          <div class="text-lg font-bold text-slate-900">{@stats.total_pending_amount} €</div>
        </div>
      </div>

      <%!-- Settings --%>
      <details class="mt-6">
        <summary class="cursor-pointer font-medium">Configuration</summary>
        <div class="bg-white rounded-xl shadow-sm border border-slate-200 mt-2">
          <div class="p-6">
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
            class={[
              if(@filter_status == "all",
                do:
                  "bg-indigo-600 text-white rounded-lg px-3 py-1.5 text-sm font-medium hover:bg-indigo-700 transition",
                else:
                  "text-sm text-slate-600 hover:bg-slate-50 rounded-lg px-3 py-1.5 font-medium transition"
              )
            ]}
            phx-click="filter"
            phx-value-status="all"
          >
            Toutes
          </button>
          <button
            class={[
              if(@filter_status == "pending",
                do:
                  "bg-amber-500 text-white rounded-lg px-3 py-1.5 text-sm font-medium hover:bg-amber-600 transition",
                else:
                  "text-sm text-slate-600 hover:bg-slate-50 rounded-lg px-3 py-1.5 font-medium transition"
              )
            ]}
            phx-click="filter"
            phx-value-status="pending"
          >
            En attente
          </button>
          <button
            class={[
              if(@filter_status == "paid",
                do:
                  "bg-green-600 text-white rounded-lg px-3 py-1.5 text-sm font-medium hover:bg-green-700 transition",
                else:
                  "text-sm text-slate-600 hover:bg-slate-50 rounded-lg px-3 py-1.5 font-medium transition"
              )
            ]}
            phx-click="filter"
            phx-value-status="paid"
          >
            Payées
          </button>
        </div>

        <div class="overflow-x-auto">
          <table class="w-full text-left" id="drums-requests-table">
            <thead>
              <tr>
                <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-3 py-2">
                  Radeau
                </th>
                <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-3 py-2">
                  Bidons
                </th>
                <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-3 py-2">
                  Montant
                </th>
                <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-3 py-2">
                  Statut
                </th>
                <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-3 py-2">
                  Date
                </th>
                <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-3 py-2">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody>
              <%= for request <- @requests do %>
                <tr id={"drum-#{request.id}"} class="border-b border-slate-100 hover:bg-slate-50">
                  <td class="px-3 py-2 text-sm font-medium">{request.crew.raft.name}</td>
                  <td class="px-3 py-2 text-sm">{request.quantity}</td>
                  <td class="px-3 py-2 text-sm">{request.total_amount} €</td>
                  <td class="px-3 py-2 text-sm">
                    <%= if request.status == "paid" do %>
                      <span class="bg-green-100 text-green-700 text-xs font-medium px-2 py-0.5 rounded-full">
                        Payé
                      </span>
                    <% else %>
                      <span class="bg-amber-100 text-amber-700 text-xs font-medium px-2 py-0.5 rounded-full">
                        En attente
                      </span>
                    <% end %>
                  </td>
                  <td class="px-3 py-2 text-sm">
                    {Calendar.strftime(request.inserted_at, "%d/%m/%Y")}
                  </td>
                  <td class="px-3 py-2 text-sm">
                    <%= if request.status == "pending" do %>
                      <button
                        class="bg-green-600 text-white rounded-md px-2 py-1 text-xs font-medium hover:bg-green-700 transition"
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
