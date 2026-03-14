defmodule HoMonRadeauWeb.Admin.UserLive.Show do
  use HoMonRadeauWeb, :live_view

  alias HoMonRadeau.Accounts
  alias HoMonRadeau.Events

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    user = Accounts.get_user!(id)
    edition = Events.get_current_edition()
    user_crew = Events.get_user_crew(user)

    raft =
      if user_crew do
        Events.get_raft!(user_crew.raft_id) |> Events.preload_raft_details()
      else
        nil
      end

    crew_membership =
      if user_crew do
        Events.get_crew_member(user_crew.id, user.id)
      else
        nil
      end

    form_status =
      if edition do
        Events.registration_form_status(user, edition.id)
      else
        nil
      end

    current_form =
      if edition do
        Events.get_current_registration_form(user.id, edition.id)
      else
        nil
      end

    {:ok,
     socket
     |> assign(:page_title, Accounts.display_name(user))
     |> assign(:user, user)
     |> assign(:edition, edition)
     |> assign(:raft, raft)
     |> assign(:crew_membership, crew_membership)
     |> assign(:form_status, form_status)
     |> assign(:current_form, current_form)}
  end

  @impl true
  def handle_event("validate", _, socket) do
    user = socket.assigns.user

    case Accounts.validate_user(user) do
      {:ok, user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Utilisateur validé.")
         |> assign(:user, user)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de la validation.")}
    end
  end

  @impl true
  def handle_event("invalidate", _, socket) do
    user = socket.assigns.user

    case Accounts.invalidate_user(user) do
      {:ok, user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Validation révoquée.")
         |> assign(:user, user)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de la révocation.")}
    end
  end

  @impl true
  def handle_event("toggle_admin", _, socket) do
    user = socket.assigns.user
    new_status = !user.is_admin

    case user
         |> Ecto.Changeset.change(is_admin: new_status)
         |> HoMonRadeau.Repo.update() do
      {:ok, user} ->
        msg = if new_status, do: "Droits admin accordés.", else: "Droits admin révoqués."

        {:noreply,
         socket
         |> put_flash(:info, msg)
         |> assign(:user, user)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {Accounts.display_name(@user)}
        <:subtitle>{@user.email}</:subtitle>
        <:actions>
          <.link
            navigate={~p"/admin/utilisateurs"}
            class="text-sm text-slate-600 hover:bg-slate-50 rounded-lg px-3 py-1.5 font-medium transition"
          >
            ← Retour à la liste
          </.link>
        </:actions>
      </.header>

      <div class="mt-8 grid gap-6 lg:grid-cols-2">
        <%!-- Informations personnelles --%>
        <div class="bg-white rounded-xl shadow-sm border border-slate-200">
          <div class="p-6">
            <h3 class="text-lg font-semibold text-slate-900">Informations personnelles</h3>

            <dl class="space-y-3 mt-2">
              <div>
                <dt class="text-sm text-slate-400">Pseudo</dt>
                <dd class="font-medium">{@user.nickname || "—"}</dd>
              </div>
              <div>
                <dt class="text-sm text-slate-400">Prénom</dt>
                <dd class="font-medium">{@user.first_name || "—"}</dd>
              </div>
              <div>
                <dt class="text-sm text-slate-400">Nom</dt>
                <dd class="font-medium">{@user.last_name || "—"}</dd>
              </div>
              <div>
                <dt class="text-sm text-slate-400">Téléphone</dt>
                <dd class="font-medium">{@user.phone_number || "—"}</dd>
              </div>
              <div>
                <dt class="text-sm text-slate-400">Inscrit·e le</dt>
                <dd class="font-medium">
                  {Calendar.strftime(@user.inserted_at, "%d/%m/%Y à %H:%M")}
                </dd>
              </div>
              <div>
                <dt class="text-sm text-slate-400">Email confirmé</dt>
                <dd class="font-medium">
                  <%= if @user.confirmed_at do %>
                    <span class="text-green-600">Oui</span>
                    ({Calendar.strftime(@user.confirmed_at, "%d/%m/%Y")})
                  <% else %>
                    <span class="text-red-600">Non</span>
                  <% end %>
                </dd>
              </div>
            </dl>
          </div>
        </div>

        <%!-- Statuts et actions --%>
        <div class="bg-white rounded-xl shadow-sm border border-slate-200">
          <div class="p-6">
            <h3 class="text-lg font-semibold text-slate-900">Statuts</h3>

            <div class="space-y-4 mt-2">
              <div class="flex items-center justify-between">
                <div>
                  <p class="font-medium">Validation équipe d'accueil</p>
                  <%= if @user.validated do %>
                    <span class="bg-green-100 text-green-700 text-xs font-medium px-2.5 py-0.5 rounded-full">
                      Validé·e
                    </span>
                  <% else %>
                    <span class="bg-amber-100 text-amber-700 text-xs font-medium px-2.5 py-0.5 rounded-full">
                      En attente
                    </span>
                  <% end %>
                </div>
                <%= if @user.validated do %>
                  <button
                    class="text-sm text-red-600 hover:bg-red-50 rounded-lg px-3 py-1.5 font-medium transition"
                    phx-click="invalidate"
                    data-confirm="Révoquer la validation ?"
                  >
                    Révoquer
                  </button>
                <% else %>
                  <button
                    class="bg-indigo-600 text-white rounded-lg px-3 py-1.5 text-sm font-medium hover:bg-indigo-700 transition"
                    phx-click="validate"
                  >
                    Valider
                  </button>
                <% end %>
              </div>

              <div class="border-t border-slate-100 my-3"></div>

              <div class="flex items-center justify-between">
                <div>
                  <p class="font-medium">Droits administrateur</p>
                  <%= if @user.is_admin do %>
                    <span class="bg-indigo-100 text-indigo-700 text-xs font-medium px-2.5 py-0.5 rounded-full">
                      Admin
                    </span>
                  <% else %>
                    <span class="bg-slate-100 text-slate-600 text-xs font-medium px-2.5 py-0.5 rounded-full">
                      Non admin
                    </span>
                  <% end %>
                </div>
                <button
                  class={"#{if @user.is_admin, do: "text-sm text-red-600 hover:bg-red-50 rounded-lg px-3 py-1.5 font-medium transition", else: "bg-slate-600 text-white rounded-lg px-5 py-2.5 font-medium hover:bg-slate-700 transition"}"}
                  phx-click="toggle_admin"
                  data-confirm={
                    if @user.is_admin,
                      do: "Retirer les droits admin ?",
                      else: "Accorder les droits admin ?"
                  }
                >
                  {if @user.is_admin, do: "Retirer", else: "Accorder"}
                </button>
              </div>
            </div>
          </div>
        </div>

        <%!-- Équipage --%>
        <div class="bg-white rounded-xl shadow-sm border border-slate-200">
          <div class="p-6">
            <h3 class="text-lg font-semibold text-slate-900">Équipage</h3>

            <%= if @raft do %>
              <div class="mt-2">
                <.link
                  navigate={~p"/radeaux/#{@raft.slug}"}
                  class="text-indigo-600 hover:underline text-lg font-medium"
                >
                  {@raft.name}
                </.link>

                <div class="flex flex-wrap gap-2 mt-2">
                  <%= if @crew_membership && @crew_membership.is_captain do %>
                    <span class="bg-indigo-100 text-indigo-700 text-xs font-medium px-2.5 py-0.5 rounded-full">
                      Capitaine
                    </span>
                  <% end %>
                  <%= if @crew_membership && @crew_membership.is_manager do %>
                    <span class="bg-indigo-100 text-indigo-600 text-xs font-medium px-2.5 py-0.5 rounded-full">
                      Gestionnaire
                    </span>
                  <% end %>
                  <%= for role <- (@crew_membership && @crew_membership.roles) || [] do %>
                    <span class="bg-slate-100 text-slate-600 text-xs font-medium px-2.5 py-0.5 rounded-full">
                      {role}
                    </span>
                  <% end %>
                </div>

                <p class="text-sm text-slate-400 mt-2">
                  Membre depuis le {Calendar.strftime(
                    @crew_membership.joined_at || @crew_membership.inserted_at,
                    "%d/%m/%Y"
                  )}
                </p>
              </div>
            <% else %>
              <p class="text-slate-400 mt-2">Aucun équipage</p>
            <% end %>
          </div>
        </div>

        <%!-- Fiche d'inscription --%>
        <div class="bg-white rounded-xl shadow-sm border border-slate-200">
          <div class="p-6">
            <h3 class="text-lg font-semibold text-slate-900">Fiche d'inscription</h3>

            <%= if @edition do %>
              <div class="mt-2">
                <%= case @form_status do %>
                  <% :missing -> %>
                    <span class="bg-slate-100 text-slate-600 text-xs font-medium px-2.5 py-0.5 rounded-full">
                      Non déposée
                    </span>
                  <% :pending -> %>
                    <span class="bg-amber-100 text-amber-700 text-xs font-medium px-2.5 py-0.5 rounded-full">
                      En attente de validation
                    </span>
                    <%= if @current_form do %>
                      <.link
                        navigate={~p"/admin/fiches/#{@current_form.id}"}
                        class="bg-indigo-600 text-white rounded-lg px-3 py-1.5 text-sm font-medium hover:bg-indigo-700 transition mt-2 inline-block"
                      >
                        Voir la fiche
                      </.link>
                    <% end %>
                  <% :approved -> %>
                    <span class="bg-green-100 text-green-700 text-xs font-medium px-2.5 py-0.5 rounded-full">
                      Approuvée
                    </span>
                    <%= if @current_form do %>
                      <.link
                        navigate={~p"/admin/fiches/#{@current_form.id}"}
                        class="text-sm text-slate-600 hover:bg-slate-50 rounded-lg px-3 py-1.5 font-medium transition mt-2 inline-block"
                      >
                        Voir la fiche
                      </.link>
                    <% end %>
                  <% :rejected -> %>
                    <span class="bg-red-100 text-red-700 text-xs font-medium px-2.5 py-0.5 rounded-full">
                      Refusée
                    </span>
                    <%= if @current_form do %>
                      <.link
                        navigate={~p"/admin/fiches/#{@current_form.id}"}
                        class="text-sm text-slate-600 hover:bg-slate-50 rounded-lg px-3 py-1.5 font-medium transition mt-2 inline-block"
                      >
                        Voir la fiche
                      </.link>
                    <% end %>
                  <% _ -> %>
                    <span class="text-slate-400">—</span>
                <% end %>
              </div>
            <% else %>
              <p class="text-slate-400 mt-2">Aucune édition en cours</p>
            <% end %>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
