defmodule HoMonRadeauWeb.RaftLive.New do
  use HoMonRadeauWeb, :live_view

  alias HoMonRadeau.Events
  alias HoMonRadeau.Events.Raft

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    # Check if user already has a crew
    case Events.get_user_crew(user) do
      nil ->
        changeset = Events.change_raft(%Raft{})

        {:ok,
         socket
         |> assign(:page_title, "Créer un radeau")
         |> assign(:form, to_form(changeset))}

      _crew ->
        {:ok,
         socket
         |> put_flash(:error, "Vous êtes déjà membre d'un équipage.")
         |> redirect(to: ~p"/mon-radeau")}
    end
  end

  @impl true
  def handle_event("validate", %{"raft" => raft_params}, socket) do
    changeset =
      %Raft{}
      |> Events.change_raft(raft_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"raft" => raft_params}, socket) do
    user = socket.assigns.current_scope.user

    case Events.create_raft_with_crew(user, raft_params) do
      {:ok, raft} ->
        {:noreply,
         socket
         |> put_flash(:info, "Votre radeau \"#{raft.name}\" a été créé !")
         |> redirect(to: ~p"/mon-radeau")}

      {:error, :no_current_edition} ->
        {:noreply, put_flash(socket, :error, "Aucune édition en cours.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Créer un nouveau radeau
        <:subtitle>
          Vous deviendrez automatiquement le premier gestionnaire de cet équipage.
        </:subtitle>
      </.header>

      <div class="mt-8 max-w-lg">
        <.form for={@form} id="raft-form" phx-change="validate" phx-submit="save" class="space-y-4">
          <.input
            field={@form[:name]}
            type="text"
            label="Nom du radeau"
            placeholder="Le Radeau de la Méduse"
            required
          />
          <p class="text-sm text-slate-400 -mt-2">
            Ce nom sera visible publiquement et doit être unique.
          </p>

          <.input
            field={@form[:description_short]}
            type="text"
            label="Description courte"
            placeholder="Une phrase pour décrire votre équipage..."
            maxlength="150"
          />
          <p class="text-sm text-slate-400 -mt-2">
            Affichée dans la liste des radeaux (150 caractères max).
          </p>

          <.input
            field={@form[:description]}
            type="textarea"
            label="Description complète"
            placeholder="Présentez votre équipage, votre projet, vos motivations..."
            rows="5"
          />

          <.input
            field={@form[:forum_url]}
            type="url"
            label="Lien forum (optionnel)"
            placeholder="https://forum.flotille-tutto-blu.org/..."
          />
          <p class="text-sm text-slate-400 -mt-2">
            Lien vers la discussion de votre équipage sur le forum.
          </p>

          <div class="flex gap-4 pt-4">
            <button
              type="submit"
              class="bg-indigo-600 text-white rounded-lg px-5 py-2.5 font-medium hover:bg-indigo-700 transition inline-flex items-center"
              phx-disable-with="Création..."
            >
              Créer le radeau
            </button>
            <.link
              navigate={~p"/radeaux"}
              class="text-slate-600 hover:bg-slate-50 rounded-lg px-5 py-2.5 font-medium transition"
            >
              Annuler
            </.link>
          </div>
        </.form>
      </div>
    </Layouts.app>
    """
  end
end
