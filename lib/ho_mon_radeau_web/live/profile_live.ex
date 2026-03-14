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
          <div class="avatar placeholder">
            <div class="bg-primary text-primary-content rounded-full w-16 h-16 flex items-center justify-center text-2xl">
              {String.first(@user.nickname || @user.email)}
            </div>
          </div>
          <div>
            <h1 class="text-2xl font-bold">
              {Accounts.display_name(@user)}
            </h1>
            <div id="validation-status" class="mt-1">
              <%= if @user.validated do %>
                <span class="badge badge-success gap-1">
                  <.icon name="hero-check-circle-mini" class="size-4" /> Compte validé
                </span>
              <% else %>
                <span class="badge badge-warning gap-1">
                  <.icon name="hero-clock-mini" class="size-4" /> En attente de validation
                </span>
              <% end %>
            </div>
            <%= if @raft do %>
              <div class="mt-1 text-sm" id="crew-membership">
                Membre de :
                <.link navigate={~p"/mon-radeau"} class="link link-primary font-medium">
                  {@raft.name}
                </.link>
              </div>
            <% end %>
            <%= if @transverse_teams != [] do %>
              <div class="mt-1 text-sm" id="transverse-teams">
                Équipes :
                <%= for team <- @transverse_teams do %>
                  <span class="badge badge-ghost badge-sm">{team.name}</span>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>

        <%!-- Validation warning --%>
        <%= unless @user.validated do %>
          <div class="alert alert-warning" id="validation-warning">
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
        <div class="card bg-base-200 shadow-sm">
          <div class="card-body">
            <h2 class="card-title text-lg">Informations personnelles</h2>

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

                <div class="form-control">
                  <label class="label cursor-pointer justify-start gap-3">
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
                      class="checkbox checkbox-primary"
                      id={@form[:profile_picture_public].id}
                    />
                    <span class="label-text">Photo de profil publique</span>
                  </label>
                  <p class="text-xs text-base-content/60 ml-10">
                    Si activé, votre photo sera visible sur les pages publiques des radeaux
                  </p>
                </div>

                <%!-- Missing name warning --%>
                <%= if is_nil(@user.first_name) or @user.first_name == "" or is_nil(@user.last_name) or @user.last_name == "" do %>
                  <div class="alert alert-info text-sm" id="name-required-warning">
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
        <div class="card bg-base-200 shadow-sm">
          <div class="card-body">
            <h2 class="card-title text-lg">Paramètres du compte</h2>
            <div class="space-y-3">
              <div class="flex items-center justify-between" id="email-setting">
                <div>
                  <span class="text-sm font-medium">Email</span>
                  <p class="text-sm text-base-content/60">{@user.email}</p>
                </div>
                <.link href={~p"/users/settings"} class="btn btn-ghost btn-sm">
                  Modifier
                </.link>
              </div>
              <div class="divider my-0" />
              <div class="flex items-center justify-between" id="password-setting">
                <div>
                  <span class="text-sm font-medium">Mot de passe</span>
                  <p class="text-sm text-base-content/60">••••••••</p>
                </div>
                <.link href={~p"/users/settings"} class="btn btn-ghost btn-sm">
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
