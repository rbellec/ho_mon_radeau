defmodule HoMonRadeauWeb.ProfileLive do
  use HoMonRadeauWeb, :live_view

  alias HoMonRadeau.Accounts
  alias HoMonRadeau.Events

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    changeset = Accounts.change_user_profile(user)
    user_crew = Events.get_user_crew(user)

    raft =
      if user_crew do
        Events.get_raft!(user_crew.raft_id)
      end

    transverse_teams = Events.get_user_transverse_teams(user)

    api_tokens = if user.validated, do: Accounts.list_active_api_tokens(user), else: []

    {:ok,
     socket
     |> assign(:page_title, "Mon profil")
     |> assign(:user, user)
     |> assign(:user_crew, user_crew)
     |> assign(:raft, raft)
     |> assign(:transverse_teams, transverse_teams)
     |> assign(:form, to_form(changeset))
     |> assign(:api_tokens, api_tokens)
     |> assign(:new_token, nil)
     |> assign(:token_label, "")}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.user
      |> Accounts.change_user_profile(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.update_user_profile(socket.assigns.user, user_params) do
      {:ok, user} ->
        changeset = Accounts.change_user_profile(user)

        {:noreply,
         socket
         |> assign(:user, user)
         |> assign(:form, to_form(changeset))
         |> put_flash(:info, "Profil mis à jour avec succès.")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("create_token", %{"label" => label}, socket) do
    user = socket.assigns.user

    case Accounts.create_api_token(user, label) do
      {:ok, raw_token, _api_token} ->
        {:noreply,
         socket
         |> assign(:new_token, raw_token)
         |> assign(:token_label, "")
         |> assign(:api_tokens, Accounts.list_active_api_tokens(user))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de la création du token.")}
    end
  end

  @impl true
  def handle_event("dismiss_token", _params, socket) do
    {:noreply, assign(socket, :new_token, nil)}
  end

  @impl true
  def handle_event("revoke_token", %{"id" => id}, socket) do
    user = socket.assigns.user

    case Accounts.revoke_api_token_by_id(user, String.to_integer(id)) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(:api_tokens, Accounts.list_active_api_tokens(user))
         |> put_flash(:info, "Token révoqué.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de la révocation.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-8">
        <%!-- Header section --%>
        <div class="flex items-center gap-4" id="profile-header">
          <div>
            <div class="bg-indigo-600 text-white rounded-full w-16 h-16 flex items-center justify-center text-2xl">
              {String.first(@user.nickname || @user.email)}
            </div>
          </div>
          <div>
            <h1 class="text-2xl font-bold">
              {Accounts.display_name(@user)}
            </h1>
            <div id="validation-status" class="mt-1">
              <%= if @user.validated do %>
                <span class="bg-green-100 text-green-700 text-xs font-medium px-2.5 py-0.5 rounded-full inline-flex items-center gap-1">
                  <.icon name="hero-check-circle-mini" class="size-4" /> Compte validé
                </span>
              <% else %>
                <span class="bg-amber-100 text-amber-700 text-xs font-medium px-2.5 py-0.5 rounded-full inline-flex items-center gap-1">
                  <.icon name="hero-clock-mini" class="size-4" /> En attente de validation
                </span>
              <% end %>
            </div>
            <%= if @raft do %>
              <div class="mt-1 text-sm" id="crew-membership">
                Membre de :
                <.link navigate={~p"/mon-radeau"} class="text-indigo-600 hover:underline font-medium">
                  {@raft.name}
                </.link>
              </div>
            <% end %>
            <%= if @transverse_teams != [] do %>
              <div class="mt-1 text-sm" id="transverse-teams">
                Équipes :
                <%= for team <- @transverse_teams do %>
                  <span class="bg-slate-100 text-slate-600 text-xs font-medium px-2 py-0.5 rounded-full">
                    {team.name}
                  </span>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>

        <%!-- Validation warning --%>
        <%= unless @user.validated do %>
          <div
            class="bg-amber-50 border border-amber-200 text-amber-800 rounded-xl p-4 flex items-start gap-3"
            id="validation-warning"
          >
            <.icon name="hero-clock" class="size-5" />
            <div>
              <p class="font-medium">
                Votre compte est en attente de validation par l'équipe d'accueil.
              </p>
              <p class="text-sm mt-1">
                Vous pourrez rejoindre un équipage une fois validé·e.
                Des questions ? Rendez-vous sur le forum.
              </p>
            </div>
          </div>
        <% end %>

        <%!-- Profile form --%>
        <div class="bg-white rounded-xl shadow-sm border border-slate-200">
          <div class="p-6">
            <h2 class="text-lg font-semibold text-slate-900">Informations personnelles</h2>

            <.form for={@form} id="profile-form" phx-change="validate" phx-submit="save">
              <div class="space-y-4">
                <.input
                  field={@form[:nickname]}
                  type="text"
                  label="Pseudo"
                  placeholder="Votre pseudo (public)"
                />
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <.input field={@form[:first_name]} type="text" label="Prénom" />
                  <.input field={@form[:last_name]} type="text" label="Nom" />
                </div>
                <.input
                  field={@form[:phone_number]}
                  type="tel"
                  label="Numéro de téléphone"
                  placeholder="06 12 34 56 78"
                />

                <div class="mb-3">
                  <label class="flex items-center gap-3 cursor-pointer">
                    <input
                      type="hidden"
                      name={@form[:profile_picture_public].name}
                      value="false"
                    />
                    <input
                      type="checkbox"
                      name={@form[:profile_picture_public].name}
                      value="true"
                      checked={
                        Phoenix.HTML.Form.normalize_value(
                          "checkbox",
                          @form[:profile_picture_public].value
                        )
                      }
                      class="w-4 h-4 rounded border-slate-300 text-indigo-600 focus:ring-indigo-500"
                      id={@form[:profile_picture_public].id}
                    />
                    <span class="text-sm text-slate-700">Photo de profil publique</span>
                  </label>
                  <p class="text-xs text-slate-400 ml-10">
                    Si activé, votre photo sera visible sur les pages publiques des radeaux
                  </p>
                </div>

                <%!-- Missing name warning --%>
                <%= if is_nil(@user.first_name) or @user.first_name == "" or is_nil(@user.last_name) or @user.last_name == "" do %>
                  <div
                    class="bg-indigo-50 border border-indigo-200 text-indigo-800 rounded-xl p-4 flex items-start gap-3 text-sm"
                    id="name-required-warning"
                  >
                    <.icon name="hero-information-circle-mini" class="size-4" />
                    <span>Prénom et Nom sont requis pour participer à l'événement.</span>
                  </div>
                <% end %>

                <div class="mt-4">
                  <.button variant="primary" phx-disable-with="Enregistrement...">
                    Enregistrer les modifications
                  </.button>
                </div>
              </div>
            </.form>
          </div>
        </div>

        <%!-- Account settings links --%>
        <div class="bg-white rounded-xl shadow-sm border border-slate-200">
          <div class="p-6">
            <h2 class="text-lg font-semibold text-slate-900">Paramètres du compte</h2>
            <div class="space-y-3">
              <div class="flex items-center justify-between" id="email-setting">
                <div>
                  <span class="text-sm font-medium">Email</span>
                  <p class="text-sm text-slate-400">{@user.email}</p>
                </div>
                <.link
                  href={~p"/users/settings"}
                  class="text-sm text-indigo-600 hover:bg-indigo-50 rounded-lg px-3 py-1.5 font-medium transition"
                >
                  Modifier
                </.link>
              </div>
              <div class="border-t border-slate-100 my-3" />
              <div class="flex items-center justify-between" id="password-setting">
                <div>
                  <span class="text-sm font-medium">Mot de passe</span>
                  <p class="text-sm text-slate-400">••••••••</p>
                </div>
                <.link
                  href={~p"/users/settings"}
                  class="text-sm text-indigo-600 hover:bg-indigo-50 rounded-lg px-3 py-1.5 font-medium transition"
                >
                  Modifier
                </.link>
              </div>
            </div>
          </div>
        </div>
        <%!-- API Tokens (admin only) --%>
        <%= if @user.validated do %>
          <div class="bg-white rounded-xl shadow-sm border border-slate-200" id="api-tokens">
            <div class="p-6">
              <h2 class="text-lg font-semibold text-slate-900 mb-1">Tokens API</h2>
              <p class="text-sm text-slate-500 mb-4">
                Créez des tokens pour accéder à l'API REST.
              </p>

              <%!-- New token alert --%>
              <%= if @new_token do %>
                <div class="bg-green-50 border border-green-200 rounded-xl p-4 mb-4">
                  <p class="text-sm font-medium text-green-800 mb-2">
                    Token créé ! Copiez-le maintenant, il ne sera plus visible ensuite.
                  </p>
                  <div class="flex items-center gap-2">
                    <code
                      class="flex-1 bg-white border border-green-300 rounded-lg px-3 py-2 text-sm font-mono select-all break-all"
                      id="new-token-value"
                    >
                      {@new_token}
                    </code>
                    <button
                      phx-click="dismiss_token"
                      class="text-slate-400 hover:text-slate-600 shrink-0"
                    >
                      <.icon name="hero-x-mark-mini" class="size-5" />
                    </button>
                  </div>
                </div>
              <% end %>

              <%!-- Create token form --%>
              <form phx-submit="create_token" class="flex items-end gap-3 mb-4">
                <div class="flex-1">
                  <label class="block text-sm font-medium text-slate-700 mb-1">
                    Nom du token
                  </label>
                  <input
                    type="text"
                    name="label"
                    value={@token_label}
                    placeholder="Donnez un nom pour identifier ce token (ex: Claude Desktop, Mon laptop...)"
                    required
                    class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
                  />
                </div>
                <button
                  type="submit"
                  class="bg-indigo-600 text-white rounded-lg px-4 py-2 text-sm font-medium hover:bg-indigo-700 transition shrink-0"
                >
                  Créer
                </button>
              </form>

              <%!-- Active tokens list --%>
              <%= if @api_tokens != [] do %>
                <div class="space-y-2">
                  <%= for token <- @api_tokens do %>
                    <div class="flex items-center justify-between py-2 px-3 bg-slate-50 rounded-lg">
                      <div>
                        <span class="text-sm font-medium text-slate-900">{token.label}</span>
                        <span class="text-xs text-slate-400 ml-2">
                          Créé le {Calendar.strftime(token.inserted_at, "%d/%m/%Y")}
                          <%= if token.last_used_at do %>
                            · Utilisé le {Calendar.strftime(token.last_used_at, "%d/%m/%Y à %H:%M")}
                          <% end %>
                        </span>
                      </div>
                      <button
                        phx-click="revoke_token"
                        phx-value-id={token.id}
                        data-confirm="Révoquer ce token ? Il ne fonctionnera plus."
                        class="text-xs text-red-600 hover:bg-red-50 rounded-md px-2 py-1 font-medium transition"
                      >
                        Révoquer
                      </button>
                    </div>
                  <% end %>
                </div>
              <% else %>
                <p class="text-sm text-slate-400 italic">Aucun token actif.</p>
              <% end %>

              <%!-- Configuration help --%>
              <details class="mt-4 border-t border-slate-100 pt-4 group">
                <summary class="cursor-pointer select-none flex items-center gap-2 text-sm font-medium text-slate-600 hover:text-slate-900">
                  <.icon
                    name="hero-chevron-down-mini"
                    class="size-4 transition-transform group-open:rotate-180"
                  /> Comment utiliser l'API ?
                </summary>
                <div class="mt-3 space-y-4 text-sm text-slate-600">
                  <p>
                    Utilisez le header
                    <code class="bg-slate-50 px-1 rounded">Authorization: Bearer VOTRE_TOKEN</code>
                    pour authentifier vos requêtes vers l'API REST.
                    La documentation OpenAPI est disponible à <code class="bg-slate-50 px-1 rounded">/api/openapi</code>.
                  </p>
                </div>
              </details>
            </div>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end
end
