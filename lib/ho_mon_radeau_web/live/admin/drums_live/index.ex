defmodule HoMonRadeauWeb.Admin.DrumsLive.Index do
  use HoMonRadeauWeb, :live_view

  alias HoMonRadeau.Drums
  alias HoMonRadeau.Events

  @impl true
  def mount(_params, _session, socket) do
    settings = Drums.get_settings()
    drum_types = Drums.list_drum_types()
    declarations = Drums.list_all_declarations()
    stats = Drums.compute_stats(declarations)

    {:ok,
     socket
     |> assign(:page_title, "Gestion des bidons")
     |> assign(:settings, settings)
     |> assign(:settings_form, to_form(Drums.change_settings(settings)))
     |> assign(:drum_types, drum_types)
     |> assign(:declarations, declarations)
     |> assign(:stats, stats)
     |> assign(:editing_type_id, nil)
     |> assign(:new_type_form, nil)
     |> assign(:filter, "all")}
  end

  @impl true
  def handle_event("filter", %{"value" => filter}, socket) do
    {:noreply, assign(socket, :filter, filter)}
  end

  # -- Settings --

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

  # -- Payment --

  @impl true
  def handle_event("validate_payment", %{"id" => id}, socket) do
    declaration = Drums.get_declaration!(id)
    admin = socket.assigns.current_scope.user

    case Drums.validate_payment(declaration, admin.id) do
      {:ok, _} ->
        declarations = Drums.list_all_declarations()

        {:noreply,
         socket
         |> assign(:declarations, declarations)
         |> assign(:stats, Drums.compute_stats(declarations))
         |> put_flash(:info, "Paiement validé pour #{declaration.crew.raft.name}.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de la validation.")}
    end
  end

  # -- Drum types --

  @impl true
  def handle_event("new_type", _params, socket) do
    {:noreply,
     socket
     |> assign(:new_type_form, to_form(Drums.change_drum_type()))
     |> assign(:editing_type_id, nil)}
  end

  @impl true
  def handle_event("cancel_type_form", _params, socket) do
    {:noreply,
     socket
     |> assign(:new_type_form, nil)
     |> assign(:editing_type_id, nil)}
  end

  @impl true
  def handle_event("save_new_type", %{"drum_type" => params}, socket) do
    case Drums.create_drum_type(params) do
      {:ok, _type} ->
        {:noreply,
         socket
         |> assign(:drum_types, Drums.list_drum_types())
         |> assign(:new_type_form, nil)
         |> put_flash(:info, "Type de bidon créé.")}

      {:error, changeset} ->
        {:noreply, assign(socket, :new_type_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("edit_type", %{"id" => id}, socket) do
    {:noreply,
     socket
     |> assign(:editing_type_id, String.to_integer(id))
     |> assign(:new_type_form, nil)}
  end

  @impl true
  def handle_event("save_type", %{"drum_type" => params, "type_id" => id}, socket) do
    type = Drums.get_drum_type!(id)

    case Drums.update_drum_type(type, params) do
      {:ok, _type} ->
        {:noreply,
         socket
         |> assign(:drum_types, Drums.list_drum_types())
         |> assign(:editing_type_id, nil)
         |> put_flash(:info, "Type mis à jour.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de la mise à jour.")}
    end
  end

  # -- CSV export --

  @impl true
  def handle_event("export_csv", _params, socket) do
    edition = Events.get_current_edition()

    if edition do
      csv_content = Drums.build_csv(edition.id)
      date = Date.utc_today() |> Date.to_string()
      filename = "export_commandes_bidons_#{date}.csv"

      {:noreply,
       push_event(socket, "download_csv", %{
         content: csv_content,
         filename: filename
       })}
    else
      {:noreply, put_flash(socket, :error, "Aucune édition en cours.")}
    end
  end

  defp filtered_declarations(declarations, "all"), do: declarations

  defp filtered_declarations(declarations, "declared"),
    do: Enum.filter(declarations, & &1.declared)

  defp filtered_declarations(declarations, "not_declared"),
    do: Enum.filter(declarations, &(!&1.declared))

  defp filtered_declarations(declarations, "paid"),
    do: Enum.filter(declarations, &(&1.status == "paid"))

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Gestion des bidons
        <:subtitle>
          {length(@declarations)} équipage{if length(@declarations) != 1, do: "s"}
        </:subtitle>
      </.header>

      <%!-- Stats --%>
      <div class="grid grid-cols-2 md:grid-cols-3 gap-4 mt-6">
        <div class="bg-slate-50 rounded-lg p-4">
          <div class="text-xs text-slate-500 font-medium">Équipages déclarés</div>
          <div class="text-lg font-bold text-slate-900">
            {@stats.total_declared} / {length(@declarations)}
          </div>
        </div>
        <div class="bg-slate-50 rounded-lg p-4">
          <div class="text-xs text-slate-500 font-medium">Paiements validés</div>
          <div class="text-lg font-bold text-slate-900">{@stats.total_paid}</div>
        </div>
        <div class="bg-slate-50 rounded-lg p-4">
          <div class="text-xs text-slate-500 font-medium">Montant perçu</div>
          <div class="text-lg font-bold text-slate-900">{@stats.total_paid_amount} €</div>
        </div>
      </div>

      <%!-- Drum types --%>
      <details class="mt-6">
        <summary class="cursor-pointer font-medium text-slate-700">
          Types de bidons ({length(@drum_types)})
        </summary>
        <div class="bg-white rounded-xl shadow-sm border border-slate-200 mt-2">
          <div class="p-4">
            <table class="w-full text-sm" id="drum-types-table">
              <thead>
                <tr>
                  <th class="text-left text-xs font-medium text-slate-500 uppercase px-3 py-2">
                    Nom
                  </th>
                  <th class="text-left text-xs font-medium text-slate-500 uppercase px-3 py-2">
                    Portance (kg)
                  </th>
                  <th class="text-left text-xs font-medium text-slate-500 uppercase px-3 py-2 hidden sm:table-cell">
                    Description
                  </th>
                  <th class="text-left text-xs font-medium text-slate-500 uppercase px-3 py-2">
                    Ordre
                  </th>
                  <th class="text-left text-xs font-medium text-slate-500 uppercase px-3 py-2">
                    Actif
                  </th>
                  <th class="px-3 py-2"></th>
                </tr>
              </thead>
              <tbody>
                <%= for type <- @drum_types do %>
                  <tr id={"type-#{type.id}"} class="border-t border-slate-100">
                    <%= if @editing_type_id == type.id do %>
                      <td colspan="6" class="px-3 py-3">
                        <form
                          phx-submit="save_type"
                          class="grid grid-cols-2 sm:grid-cols-4 gap-2 items-end"
                        >
                          <input type="hidden" name="type_id" value={type.id} />
                          <div>
                            <label class="text-xs text-slate-500">Nom</label>
                            <input
                              type="text"
                              name="drum_type[name]"
                              value={type.name}
                              class="block w-full rounded-md border border-slate-300 px-2 py-1 text-sm"
                            />
                          </div>
                          <div>
                            <label class="text-xs text-slate-500">Portance (kg)</label>
                            <input
                              type="number"
                              name="drum_type[buoyancy_kg]"
                              value={type.buoyancy_kg}
                              class="block w-full rounded-md border border-slate-300 px-2 py-1 text-sm"
                            />
                          </div>
                          <div>
                            <label class="text-xs text-slate-500">Ordre</label>
                            <input
                              type="number"
                              name="drum_type[position]"
                              value={type.position}
                              class="block w-full rounded-md border border-slate-300 px-2 py-1 text-sm"
                            />
                          </div>
                          <div class="sm:col-span-4">
                            <label class="text-xs text-slate-500">Description</label>
                            <input
                              type="text"
                              name="drum_type[description]"
                              value={type.description}
                              class="block w-full rounded-md border border-slate-300 px-2 py-1 text-sm"
                            />
                          </div>
                          <div class="flex items-center gap-2">
                            <input
                              type="checkbox"
                              name="drum_type[active]"
                              value="true"
                              checked={type.active}
                              class="rounded border-slate-300"
                            />
                            <label class="text-xs text-slate-600">Actif</label>
                          </div>
                          <div class="flex gap-2">
                            <button
                              type="submit"
                              class="bg-indigo-600 text-white rounded-md px-3 py-1 text-xs font-medium hover:bg-indigo-700"
                            >
                              Sauvegarder
                            </button>
                            <button
                              type="button"
                              phx-click="cancel_type_form"
                              class="text-slate-600 hover:bg-slate-50 rounded-md px-3 py-1 text-xs font-medium"
                            >
                              Annuler
                            </button>
                          </div>
                        </form>
                      </td>
                    <% else %>
                      <td class="px-3 py-2 font-medium">{type.name}</td>
                      <td class="px-3 py-2">{type.buoyancy_kg || "—"}</td>
                      <td class="px-3 py-2 text-slate-500 text-xs hidden sm:table-cell">
                        {type.description}
                      </td>
                      <td class="px-3 py-2">{type.position}</td>
                      <td class="px-3 py-2">
                        <%= if type.active do %>
                          <span class="bg-green-100 text-green-700 text-xs px-1.5 py-0.5 rounded-full">
                            oui
                          </span>
                        <% else %>
                          <span class="bg-slate-100 text-slate-500 text-xs px-1.5 py-0.5 rounded-full">
                            non
                          </span>
                        <% end %>
                      </td>
                      <td class="px-3 py-2">
                        <button
                          phx-click="edit_type"
                          phx-value-id={type.id}
                          class="text-slate-500 hover:text-indigo-600 text-xs font-medium"
                        >
                          Modifier
                        </button>
                      </td>
                    <% end %>
                  </tr>
                <% end %>
                <%!-- New type form --%>
                <%= if @new_type_form do %>
                  <tr class="border-t border-slate-100 bg-slate-50">
                    <td colspan="6" class="px-3 py-3">
                      <.form
                        for={@new_type_form}
                        phx-submit="save_new_type"
                        class="grid grid-cols-2 sm:grid-cols-4 gap-2 items-end"
                      >
                        <div>
                          <label class="text-xs text-slate-500">Nom *</label>
                          <.input field={@new_type_form[:name]} type="text" label="" />
                        </div>
                        <div>
                          <label class="text-xs text-slate-500">Portance (kg)</label>
                          <.input field={@new_type_form[:buoyancy_kg]} type="number" label="" />
                        </div>
                        <div>
                          <label class="text-xs text-slate-500">Ordre</label>
                          <.input field={@new_type_form[:position]} type="number" label="" />
                        </div>
                        <div class="sm:col-span-4">
                          <label class="text-xs text-slate-500">Description</label>
                          <.input field={@new_type_form[:description]} type="text" label="" />
                        </div>
                        <div class="flex gap-2">
                          <.button variant="primary" phx-disable-with="Création...">Créer</.button>
                          <button
                            type="button"
                            phx-click="cancel_type_form"
                            class="text-slate-600 hover:bg-slate-50 rounded-md px-3 py-1 text-sm font-medium"
                          >
                            Annuler
                          </button>
                        </div>
                      </.form>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
            <%= if is_nil(@new_type_form) && is_nil(@editing_type_id) do %>
              <div class="mt-3">
                <button
                  phx-click="new_type"
                  class="text-sm text-indigo-600 hover:text-indigo-700 font-medium inline-flex items-center gap-1"
                >
                  <.icon name="hero-plus-mini" class="size-4" /> Ajouter un type
                </button>
              </div>
            <% end %>
          </div>
        </div>
      </details>

      <%!-- Settings --%>
      <details class="mt-4">
        <summary class="cursor-pointer font-medium text-slate-700">Configuration</summary>
        <div class="bg-white rounded-xl shadow-sm border border-slate-200 mt-2">
          <div class="p-6">
            <.form for={@settings_form} id="drum-settings-form" phx-submit="update_settings">
              <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <.input
                  field={@settings_form[:forfait_price]}
                  type="number"
                  label="Tarif forfaitaire par bidon (€)"
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

      <%!-- Filter + export --%>
      <div class="mt-6 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div class="flex gap-2 flex-wrap">
          <%= for {label, value} <- [{"Tous", "all"}, {"Déclarés", "declared"}, {"Non déclarés", "not_declared"}, {"Payés", "paid"}] do %>
            <button
              phx-click="filter"
              phx-value-value={value}
              class={[
                "rounded-lg px-3 py-1.5 text-sm font-medium transition",
                if(@filter == value,
                  do: "bg-indigo-600 text-white",
                  else: "text-slate-600 hover:bg-slate-50"
                )
              ]}
            >
              {label}
            </button>
          <% end %>
        </div>
        <button
          phx-click="export_csv"
          class="text-sm text-slate-600 hover:bg-slate-50 border border-slate-300 rounded-lg px-3 py-1.5 font-medium transition inline-flex items-center gap-1"
        >
          <.icon name="hero-arrow-down-tray-mini" class="size-4" /> Exporter CSV
        </button>
      </div>

      <%!-- Declarations table --%>
      <% visible = filtered_declarations(@declarations, @filter) %>
      <% types = @drum_types |> Enum.filter(& &1.active) %>
      <div class="overflow-x-auto mt-3">
        <table class="w-full text-left" id="drums-declarations-table">
          <thead>
            <tr>
              <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-3 py-2">
                Radeau
              </th>
              <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-3 py-2">
                Validé
              </th>
              <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-3 py-2">
                Déclaré
              </th>
              <%= for type <- types do %>
                <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-3 py-2 hidden lg:table-cell">
                  {type.name}
                </th>
              <% end %>
              <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-3 py-2">
                Total
              </th>
              <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-3 py-2">
                Paiement
              </th>
              <th class="bg-slate-50 text-slate-500 text-xs font-medium uppercase px-3 py-2">
                Actions
              </th>
            </tr>
          </thead>
          <tbody>
            <%= for decl <- visible do %>
              <tr id={"decl-#{decl.id}"} class="border-b border-slate-100 hover:bg-slate-50">
                <td class="px-3 py-2 text-sm font-medium">{decl.crew.raft.name}</td>
                <td class="px-3 py-2 text-sm">
                  <%= if decl.crew.raft.validated do %>
                    <span class="bg-green-100 text-green-700 text-xs px-1.5 py-0.5 rounded-full">
                      oui
                    </span>
                  <% else %>
                    <span class="bg-slate-100 text-slate-500 text-xs px-1.5 py-0.5 rounded-full">
                      non
                    </span>
                  <% end %>
                </td>
                <td class="px-3 py-2 text-sm">
                  <%= if decl.declared do %>
                    <span class="bg-sky-100 text-sky-700 text-xs px-1.5 py-0.5 rounded-full">
                      oui
                    </span>
                  <% else %>
                    <span class="bg-amber-100 text-amber-700 text-xs px-1.5 py-0.5 rounded-full">
                      non
                    </span>
                  <% end %>
                </td>
                <%!-- Per-type columns --%>
                <%= for type <- types do %>
                  <td class="px-3 py-2 text-sm hidden lg:table-cell">
                    <%= cond do %>
                      <% !decl.declared -> %>
                        <span class="text-slate-300">—</span>
                      <% decl.mode == "simple" -> %>
                        <span class="text-slate-400 text-xs italic">forfait</span>
                      <% true -> %>
                        <% qty =
                          Enum.find_value(decl.lines, 0, fn l ->
                            if l.drum_type_id == type.id, do: l.quantity
                          end) %>
                        {qty}
                    <% end %>
                  </td>
                <% end %>
                <%!-- Total --%>
                <td class="px-3 py-2 text-sm font-medium">
                  <%= cond do %>
                    <% !decl.declared -> %>
                      <span class="text-slate-300">—</span>
                    <% decl.mode == "simple" -> %>
                      {decl.total_quantity}
                    <% true -> %>
                      {decl.lines |> Enum.map(& &1.quantity) |> Enum.sum()}
                  <% end %>
                </td>
                <%!-- Payment --%>
                <td class="px-3 py-2 text-sm">
                  <%= if decl.status == "paid" do %>
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
                  <%= if decl.declared && decl.status == "pending" do %>
                    <button
                      class="bg-green-600 text-white rounded-md px-2 py-1 text-xs font-medium hover:bg-green-700 transition"
                      phx-click="validate_payment"
                      phx-value-id={decl.id}
                      data-confirm={"Valider le paiement pour #{decl.crew.raft.name} ?"}
                    >
                      Valider paiement
                    </button>
                  <% end %>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
        <%= if visible == [] do %>
          <p class="text-sm text-slate-400 italic text-center py-6">Aucune déclaration.</p>
        <% end %>
      </div>

      <%!-- JS hook for CSV download --%>
      <div id="csv-downloader" phx-hook="CsvDownloader"></div>
    </Layouts.app>
    """
  end
end
