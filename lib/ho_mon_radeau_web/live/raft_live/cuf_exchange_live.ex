defmodule HoMonRadeauWeb.RaftLive.CufExchangeLive do
  use HoMonRadeauWeb, :live_view

  alias HoMonRadeau.CUF
  alias HoMonRadeau.Events

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
        {:ok,
         socket
         |> assign(:crew, crew)
         |> assign(:raft, Events.get_raft!(crew.raft_id))
         |> assign(:page_title, "À vot'bon Cuf")
         |> load_data()}
    end
  end

  @impl true
  def handle_event("save_received", %{"count" => count}, socket) do
    case CUF.update_received_count(socket.assigns.crew, count) do
      {:ok, updated_crew} ->
        {:noreply,
         socket
         |> assign(:crew, updated_crew)
         |> put_flash(:info, "Nombre de CUF reçues mis à jour.")
         |> load_data()}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Merci d'indiquer un nombre valide (0 ou plus).")}
    end
  end

  @impl true
  def handle_event("post_listing", %{"kind" => kind, "quantity" => quantity} = params, socket) do
    attrs = %{"kind" => kind, "quantity" => quantity, "note" => Map.get(params, "note", "")}

    case CUF.upsert_exchange_listing(socket.assigns.crew.id, attrs) do
      {:ok, _listing} ->
        {:noreply,
         socket
         |> put_flash(:info, "Annonce publiée sur le marché.")
         |> load_data()}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de la publication de l'annonce.")}
    end
  end

  @impl true
  def handle_event("cancel_listing", _params, socket) do
    case socket.assigns.my_listing do
      nil ->
        {:noreply, socket}

      listing ->
        {:ok, _} = CUF.cancel_exchange_listing(listing)

        {:noreply,
         socket
         |> put_flash(:info, "Annonce annulée.")
         |> load_data()}
    end
  end

  @impl true
  def handle_event("give_cuf", %{"to_crew_id" => to_crew_id, "quantity" => quantity}, socket) do
    crew = socket.assigns.crew
    user = socket.assigns.current_scope.user

    with {to_id, ""} <- Integer.parse(to_crew_id),
         {qty, ""} <- Integer.parse(quantity) do
      case CUF.transfer_cuf(crew.id, to_id, qty, user) do
        {:ok, _result} ->
          {:noreply,
           socket
           |> put_flash(:info, "CUF transférées.")
           |> load_data()}

        {:error, _step, _changeset, _changes} ->
          {:noreply,
           put_flash(
             socket,
             :error,
             "Impossible de transférer : vérifiez le nombre de CUF disponibles."
           )}
      end
    else
      _ ->
        {:noreply,
         put_flash(socket, :error, "Merci de choisir un équipage et un nombre valides.")}
    end
  end

  defp load_data(socket) do
    crew = socket.assigns.crew
    edition = Events.get_current_edition()

    socket
    |> assign(:cuf_status, CUF.get_cuf_status(crew.id))
    |> assign(:my_listing, CUF.get_open_exchange_listing(crew.id))
    |> assign(
      :other_listings,
      if(edition, do: CUF.list_open_exchange_listings(edition.id, crew.id), else: [])
    )
    |> assign(
      :other_crews,
      if(edition, do: CUF.list_other_crews(edition.id, crew.id), else: [])
    )
    |> assign(:transfers, CUF.list_crew_transfers(crew.id))
  end

  defp status_message(%{deficit: deficit}) when deficit > 0 do
    {"il vous manque #{deficit} CUF#{if deficit > 1, do: "s"} — À vot'bon Cuf !", "amber"}
  end

  defp status_message(%{deficit: deficit}) when deficit < 0 do
    n = -deficit
    {"#{n} CUF#{if n > 1, do: "s"} en trop, les offrir ?", "sky"}
  end

  defp status_message(_status), do: {"vous êtes à jour", "green"}

  defp kind_label("request"), do: "Demande"
  defp kind_label("offer"), do: "Offre"

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :status_message, status_message(assigns.cuf_status))

    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-2xl mx-auto">
        <div class="flex items-center gap-3 mb-1">
          <.link navigate={~p"/mon-radeau"} class="text-slate-400 hover:text-slate-600 transition">
            <.icon name="hero-arrow-left-mini" class="size-5" />
          </.link>
          <h1 class="text-2xl font-bold text-slate-900">À vot'bon Cuf — {@raft.name}</h1>
        </div>
        <p class="text-sm text-slate-500 mt-1 mb-6">
          Les échanges de CUF entre équipages se discutent ailleurs (forum, etc.) — cette page sert
          à publier vos demandes/offres et à enregistrer les transferts une fois actés.
        </p>

        <%!-- Status card --%>
        <% {message, color} = @status_message %>
        <div class={[
          "rounded-xl p-4 flex items-center justify-between gap-3 border",
          color == "amber" && "bg-amber-50 border-amber-200 text-amber-800",
          color == "sky" && "bg-sky-50 border-sky-200 text-sky-800",
          color == "green" && "bg-green-50 border-green-200 text-green-800"
        ]}>
          <div>
            <p class="font-semibold">
              CUF : {@cuf_status.available} / {@cuf_status.needed}
            </p>
            <p class="text-sm">{message}</p>
          </div>
        </div>

        <%!-- Edit received count --%>
        <div class="bg-white rounded-xl shadow-sm border border-slate-200 mt-4 p-6">
          <h3 class="text-lg font-semibold text-slate-900">Nos CUF reçues</h3>
          <p class="text-sm text-slate-500 mt-1">
            Renseignez le nombre de CUF que votre équipage a reçues à ce jour. Tout le monde dans
            l'équipage peut corriger ce chiffre — merci de rester honnête, ce champ pourra être
            restreint aux admins si besoin.
          </p>
          <form phx-submit="save_received" class="mt-3 flex items-end gap-3">
            <div>
              <label class="block text-xs text-slate-500 mb-1">CUF reçues</label>
              <input
                type="number"
                name="count"
                min="0"
                value={@cuf_status.received}
                class="w-24 rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
              />
            </div>
            <button
              type="submit"
              class="bg-indigo-600 text-white rounded-lg px-4 py-2 text-sm font-medium hover:bg-indigo-700 transition"
              phx-disable-with="Enregistrement..."
            >
              Enregistrer
            </button>
          </form>
        </div>

        <%!-- Post / cancel a listing --%>
        <div class="bg-white rounded-xl shadow-sm border border-slate-200 mt-4 p-6" id="post-listing">
          <h3 class="text-lg font-semibold text-slate-900">Publier une annonce</h3>

          <%= if @my_listing do %>
            <div class="mt-3 flex items-center justify-between bg-slate-50 rounded-lg px-4 py-3">
              <p class="text-sm text-slate-700">
                <span class="font-medium">{kind_label(@my_listing.kind)}</span>
                de {@my_listing.quantity} CUF{if @my_listing.quantity > 1, do: "s"}
                <%= if @my_listing.note not in [nil, ""] do %>
                  — <span class="italic">{@my_listing.note}</span>
                <% end %>
              </p>
              <button
                phx-click="cancel_listing"
                data-confirm="Annuler cette annonce ?"
                class="text-sm text-red-600 hover:bg-red-50 rounded-lg px-3 py-1.5 font-medium transition"
              >
                Annuler
              </button>
            </div>
          <% else %>
            <form phx-submit="post_listing" class="mt-3 space-y-3">
              <div class="flex gap-4">
                <label class="flex items-center gap-2 cursor-pointer">
                  <input type="radio" name="kind" value="request" checked class="text-indigo-600" />
                  <span class="text-sm">Je cherche des CUF</span>
                </label>
                <label class="flex items-center gap-2 cursor-pointer">
                  <input type="radio" name="kind" value="offer" class="text-indigo-600" />
                  <span class="text-sm">J'ai des CUF à offrir</span>
                </label>
              </div>
              <div class="flex gap-3 items-end">
                <div>
                  <label class="block text-xs text-slate-500 mb-1">Quantité</label>
                  <input
                    type="number"
                    name="quantity"
                    min="1"
                    value="1"
                    class="w-24 rounded-lg border border-slate-300 px-3 py-2 text-sm"
                  />
                </div>
                <div class="flex-1">
                  <label class="block text-xs text-slate-500 mb-1">Note (optionnel)</label>
                  <input
                    type="text"
                    name="note"
                    placeholder="Lien vers le forum, précisions..."
                    class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
                  />
                </div>
              </div>
              <button
                type="submit"
                class="bg-indigo-600 text-white rounded-lg px-4 py-2 text-sm font-medium hover:bg-indigo-700 transition"
                phx-disable-with="Publication..."
              >
                Publier
              </button>
            </form>
          <% end %>
        </div>

        <%!-- Give CUFs --%>
        <div class="bg-white rounded-xl shadow-sm border border-slate-200 mt-4 p-6">
          <h3 class="text-lg font-semibold text-slate-900">Donner des CUF à un équipage</h3>
          <p class="text-sm text-slate-500 mt-1">
            Une fois l'échange convenu ailleurs, enregistrez-le ici — l'opération est faite par
            l'équipage qui donne.
          </p>
          <%= if @other_crews == [] do %>
            <p class="text-sm text-slate-400 italic mt-3">Aucun autre équipage disponible.</p>
          <% else %>
            <form phx-submit="give_cuf" class="mt-3 flex flex-wrap gap-3 items-end">
              <div>
                <label class="block text-xs text-slate-500 mb-1">Équipage destinataire</label>
                <select
                  name="to_crew_id"
                  class="rounded-lg border border-slate-300 px-3 py-2 text-sm"
                >
                  <%= for c <- @other_crews do %>
                    <option value={c.id}>{c.raft_name}</option>
                  <% end %>
                </select>
              </div>
              <div>
                <label class="block text-xs text-slate-500 mb-1">Quantité</label>
                <input
                  type="number"
                  name="quantity"
                  min="1"
                  value="1"
                  class="w-24 rounded-lg border border-slate-300 px-3 py-2 text-sm"
                />
              </div>
              <button
                type="submit"
                class="bg-indigo-600 text-white rounded-lg px-4 py-2 text-sm font-medium hover:bg-indigo-700 transition"
                data-confirm="Confirmer le transfert de CUF ?"
                phx-disable-with="Transfert..."
              >
                Donner
              </button>
            </form>
          <% end %>
        </div>

        <%!-- History --%>
        <%= if @transfers != [] do %>
          <div class="bg-white rounded-xl shadow-sm border border-slate-200 mt-4 p-6">
            <h3 class="text-lg font-semibold text-slate-900">Historique</h3>
            <ul class="mt-2 space-y-1 text-sm">
              <%= for t <- @transfers do %>
                <li class="text-slate-600">
                  <%= if t.from_crew_id == @crew.id do %>
                    Donné {t.quantity} CUF{if t.quantity > 1, do: "s"} à
                    <span class="font-medium">{t.to_crew.raft.name}</span>
                  <% else %>
                    Reçu {t.quantity} CUF{if t.quantity > 1, do: "s"} de
                    <span class="font-medium">{t.from_crew.raft.name}</span>
                  <% end %>
                  <span class="text-xs text-slate-400">
                    ({Calendar.strftime(t.inserted_at, "%d/%m/%Y")})
                  </span>
                </li>
              <% end %>
            </ul>
          </div>
        <% end %>

        <%!-- Board --%>
        <div class="bg-white rounded-xl shadow-sm border border-slate-200 mt-4 p-6">
          <h3 class="text-lg font-semibold text-slate-900">Le marché</h3>
          <p class="text-sm text-slate-500 mt-1">
            Les annonces des autres équipages. Tous les radeaux ne passent pas par cette page —
            pensez aussi au forum.
          </p>
          <%= if @other_listings == [] do %>
            <p class="text-sm text-slate-400 italic mt-3">Aucune annonce pour le moment.</p>
          <% else %>
            <ul class="mt-3 space-y-2">
              <%= for listing <- @other_listings do %>
                <li class="flex items-center justify-between bg-slate-50 rounded-lg px-4 py-3">
                  <div>
                    <p class="text-sm">
                      <span class="font-medium">{listing.crew.raft.name}</span>
                      — {kind_label(listing.kind)} de {listing.quantity} CUF{if listing.quantity >
                                                                                  1,
                                                                                do: "s"}
                    </p>
                    <%= if listing.note not in [nil, ""] do %>
                      <p class="text-xs text-slate-500 italic">{listing.note}</p>
                    <% end %>
                  </div>
                  <span class={[
                    "text-xs px-2 py-0.5 rounded-full font-medium",
                    listing.kind == "request" && "bg-amber-100 text-amber-700",
                    listing.kind == "offer" && "bg-sky-100 text-sky-700"
                  ]}>
                    {kind_label(listing.kind)}
                  </span>
                </li>
              <% end %>
            </ul>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
