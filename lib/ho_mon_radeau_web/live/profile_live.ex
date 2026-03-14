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

    {:ok,
     socket
     |> assign(:page_title, "Mon profil")
     |> assign(:user, user)
     |> assign(:user_crew, user_crew)
     |> assign(:raft, raft)
     |> assign(:transverse_teams, transverse_teams)
     |> assign(:form, to_form(changeset))}
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
      </div>
    </Layouts.app>
    """
  end
end
