defmodule HoMonRadeauWeb.RaftLive.DrumsLive do
  use HoMonRadeauWeb, :live_view

  alias HoMonRadeau.Drums
  alias HoMonRadeau.Events

  @notion_url "https://carnetbleu.notion.site/La-flottaison-et-les-bidons-209d51b5bb228042835ee53c9f000a79"
  @forum_url "https://tuttoblu.discourse.group/t/construire-son-radeau/11/4"

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    case Events.get_user_crew(user) do
      nil ->
        {:ok,
         socket
         |> put_flash(:info, "Vous n'êtes pas encore membre d'un équipage.")
         |> redirect(to: ~p"/radeaux")}

      crew ->
        declaration = Drums.get_or_build_declaration(crew.id)
        drum_types = Drums.list_active_drum_types()
        settings = Drums.get_settings()

        lines_by_type =
          Map.new(declaration.lines || [], fn l -> {l.drum_type_id, l.quantity} end)

        {:ok,
         socket
         |> assign(:crew, crew)
         |> assign(:raft, Events.get_raft!(crew.raft_id))
         |> assign(:declaration, declaration)
         |> assign(:drum_types, drum_types)
         |> assign(:settings, settings)
         |> assign(:lines_by_type, lines_by_type)
         |> assign(:mode, declaration.mode || "simple")
         |> assign(:page_title, "Bidons — déclaration")
         |> assign(:notion_url, @notion_url)
         |> assign(:forum_url, @forum_url)}
    end
  end

  @impl true
  def handle_event("set_mode", %{"mode" => mode}, socket) when mode in ["simple", "specific"] do
    {:noreply, assign(socket, :mode, mode)}
  end

  @impl true
  def handle_event("submit_declaration", params, socket) do
    crew = socket.assigns.crew
    mode = socket.assigns.mode

    attrs = build_attrs(params, mode)

    case Drums.submit_declaration(crew.id, attrs) do
      {:ok, declaration} ->
        lines_by_type = Map.new(declaration.lines || [], fn l -> {l.drum_type_id, l.quantity} end)

        {:noreply,
         socket
         |> assign(:declaration, declaration)
         |> assign(:lines_by_type, lines_by_type)
         |> put_flash(:info, "Déclaration enregistrée.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de l'enregistrement.")}
    end
  end

  defp build_attrs(%{"total_quantity" => qty, "notes" => notes}, "simple") do
    %{"mode" => "simple", "total_quantity" => qty, "notes" => notes}
  end

  defp build_attrs(params, "specific") do
    lines = Map.get(params, "lines", %{})
    notes = Map.get(params, "notes", "")
    %{"mode" => "specific", "lines" => lines, "notes" => notes}
  end

  defp build_attrs(params, mode), do: Map.put(params, "mode", mode)

  defp has_specific_data?(%{declared: true, mode: "specific", lines: lines}) when is_list(lines) do
    Enum.any?(lines, &((&1.quantity || 0) > 0))
  end

  defp has_specific_data?(_), do: false

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-2xl mx-auto">
        <%!-- Header --%>
        <div class="flex items-center gap-3 mb-1">
          <.link
            navigate={~p"/mon-radeau"}
            class="text-slate-400 hover:text-slate-600 transition"
          >
            <.icon name="hero-arrow-left-mini" class="size-5" />
          </.link>
          <h1 class="text-2xl font-bold text-slate-900">Bidons — {@raft.name}</h1>
        </div>

        <%!-- Info / links --%>
        <div class="bg-sky-50 border border-sky-200 rounded-xl p-4 mt-4 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <p class="text-sm text-sky-800">
            Déclarez le nombre de bidons dont votre radeau aura besoin pour la flottaison.
          </p>
          <div class="flex gap-3 shrink-0">
            <a
              href={@notion_url}
              target="_blank"
              class="text-sm text-sky-700 hover:text-sky-900 font-medium inline-flex items-center gap-1 underline underline-offset-2"
            >
              <.icon name="hero-book-open-mini" class="size-4" /> Guide bidons
            </a>
            <a
              href={@forum_url}
              target="_blank"
              class="text-sm text-sky-700 hover:text-sky-900 font-medium inline-flex items-center gap-1 underline underline-offset-2"
            >
              <.icon name="hero-chat-bubble-left-right-mini" class="size-4" /> Forum
            </a>
          </div>
        </div>

        <%!-- Current status --%>
        <div class="mt-4">
          <%= if @declaration.declared do %>
            <div class="flex items-center gap-2 text-sm text-green-700 bg-green-50 border border-green-200 rounded-lg px-4 py-2">
              <.icon name="hero-check-circle-mini" class="size-4" />
              <span>
                Déclaration soumise le {Calendar.strftime(
                  @declaration.declared_at,
                  "%d/%m/%Y à %H:%M"
                )} — vous pouvez la modifier ci-dessous.
              </span>
            </div>
          <% else %>
            <div class="flex items-center gap-2 text-sm text-amber-700 bg-amber-50 border border-amber-200 rounded-lg px-4 py-2">
              <.icon name="hero-exclamation-triangle-mini" class="size-4" />
              <span>Pas encore déclaré.</span>
            </div>
          <% end %>
        </div>

        <%!-- Payment status (if paid) --%>
        <%= if @declaration.status == "paid" do %>
          <div class="flex items-center gap-2 text-sm text-green-700 bg-green-50 border border-green-200 rounded-lg px-4 py-2 mt-2">
            <.icon name="hero-banknotes-mini" class="size-4" />
            <span>
              Paiement validé
              <%= if @declaration.total_amount do %>
                — {@declaration.total_amount} €
              <% end %>
            </span>
          </div>
        <% end %>

        <%!-- Declaration form --%>
        <form phx-submit="submit_declaration" id="drums-declaration-form" class="mt-6 space-y-4">
          <input type="hidden" name="mode" value={@mode} />

          <%= if @mode == "simple" do %>
            <div>
              <label class="block text-sm font-medium text-slate-700 mb-1">
                Nombre de bidons souhaités
              </label>
              <input
                type="number"
                name="total_quantity"
                min="0"
                value={@declaration.total_quantity || ""}
                class="block w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
                placeholder="0"
              />
              <p class="text-xs text-slate-400 mt-1">
                Portance estimée : ~70 kg/bidon. Saisissez 0 si vous n'avez pas besoin
                de bidons (autre solution de flottaison).
              </p>
            </div>
            <button
              type="button"
              phx-click="set_mode"
              phx-value-mode="specific"
              class="text-sm text-indigo-600 hover:text-indigo-700 font-medium inline-flex items-center gap-1"
            >
              Préciser les types par contrainte de construction
              <.icon name="hero-arrow-right-mini" class="size-4" />
            </button>
          <% else %>
            <div class="flex items-center justify-between">
              <p class="text-sm text-slate-600">
                Précisez les quantités par type de bidon.
              </p>
              <button
                type="button"
                phx-click="set_mode"
                phx-value-mode="simple"
                data-confirm={
                  if has_specific_data?(@declaration),
                    do:
                      "Vous avez une déclaration détaillée enregistrée. Revenir au mode simple écrasera ces quantités lors de la prochaine sauvegarde. Continuer ?",
                    else: nil
                }
                class="text-sm text-slate-500 hover:text-slate-700 font-medium inline-flex items-center gap-1"
              >
                <.icon name="hero-arrow-left-mini" class="size-4" /> Revenir au mode simple
              </button>
            </div>
            <%!-- Drum types table --%>
            <div class="overflow-x-auto rounded-xl border border-slate-200">
              <table class="w-full text-left text-sm">
                <thead>
                  <tr>
                    <th class="bg-slate-50 px-4 py-2 text-xs font-medium uppercase text-slate-500">
                      Type
                    </th>
                    <th class="bg-slate-50 px-4 py-2 text-xs font-medium uppercase text-slate-500">
                      Portance
                    </th>
                    <th class="bg-slate-50 px-4 py-2 text-xs font-medium uppercase text-slate-500 hidden sm:table-cell">
                      Dimensions
                    </th>
                    <th class="bg-slate-50 px-4 py-2 text-xs font-medium uppercase text-slate-500">
                      Quantité
                    </th>
                  </tr>
                </thead>
                <tbody>
                  <%= for type <- @drum_types do %>
                    <tr class="border-t border-slate-100">
                      <td class="px-4 py-3 font-medium">{type.name}</td>
                      <td class="px-4 py-3 text-slate-600">
                        <%= if type.buoyancy_kg do %>
                          ~{type.buoyancy_kg} kg
                        <% else %>
                          <span class="text-slate-400 italic">à confirmer</span>
                        <% end %>
                      </td>
                      <td class="px-4 py-3 text-slate-500 hidden sm:table-cell">
                        <%= if type.description do %>
                          <span class="text-xs">{type.description}</span>
                        <% end %>
                      </td>
                      <td class="px-4 py-3">
                        <input
                          type="number"
                          name={"lines[#{type.id}]"}
                          min="0"
                          value={@lines_by_type[type.id] || 0}
                          class="w-20 rounded-lg border border-slate-300 px-2 py-1 text-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
                        />
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          <% end %>

          <div>
            <label class="block text-sm font-medium text-slate-700 mb-1">
              Notes (optionnel)
            </label>
            <textarea
              name="notes"
              rows="2"
              class="block w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
              placeholder="Contraintes de construction, questions..."
            ><%= @declaration.notes %></textarea>
          </div>

          <%= if @settings.rib_iban do %>
            <div class="bg-slate-50 rounded-lg px-4 py-3 text-sm text-slate-600">
              <p class="font-medium">Règlement par virement</p>
              <p>
                IBAN : {@settings.rib_iban}
                <%= if @settings.rib_bic do %>
                  — BIC : {@settings.rib_bic}
                <% end %>
              </p>
              <%= if @settings.forfait_price do %>
                <p class="mt-1">Tarif forfaitaire : {@settings.forfait_price} € / bidon</p>
              <% end %>
            </div>
          <% end %>

          <button
            type="submit"
            class="w-full bg-indigo-600 text-white rounded-lg px-4 py-2.5 text-sm font-medium hover:bg-indigo-700 transition"
            phx-disable-with="Enregistrement..."
          >
            Enregistrer la déclaration
          </button>
        </form>
      </div>
    </Layouts.app>
    """
  end
end
