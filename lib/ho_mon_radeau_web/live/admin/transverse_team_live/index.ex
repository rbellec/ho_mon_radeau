defmodule HoMonRadeauWeb.Admin.TransverseTeamLive.Index do
  use HoMonRadeauWeb, :live_view

  alias HoMonRadeau.Events
  alias HoMonRadeau.Events.Crew

  @type_labels %{
    "welcome_team" => "Accueil",
    "safe_team" => "SAFE",
    "drums_team" => "Bidons",
    "security" => "Sécurité",
    "medical" => "Médecine",
    "other" => "Autre"
  }

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Équipes transverses")
     |> assign(:show_form, false)
     |> assign(:form, to_form(Events.change_transverse_team(%Crew{})))
     |> load_teams()}
  end

  @impl true
  def handle_event("show_form", _params, socket) do
    {:noreply, assign(socket, :show_form, true)}
  end

  @impl true
  def handle_event("cancel_form", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_form, false)
     |> assign(:form, to_form(Events.change_transverse_team(%Crew{})))}
  end

  @impl true
  def handle_event("validate_team", %{"crew" => params}, socket) do
    changeset =
      %Crew{}
      |> Events.change_transverse_team(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("create_team", %{"crew" => params}, socket) do
    case Events.create_transverse_team(params) do
      {:ok, team} ->
        {:noreply,
         socket
         |> put_flash(:info, "Équipe \"#{team.name}\" créée.")
         |> assign(:show_form, false)
         |> assign(:form, to_form(Events.change_transverse_team(%Crew{})))
         |> load_teams()}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("delete_team", %{"id" => id}, socket) do
    team = Events.get_transverse_team!(id)

    case Events.delete_transverse_team(team) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Équipe supprimée.")
         |> load_teams()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de la suppression.")}
    end
  end

  defp load_teams(socket) do
    assign(socket, :teams, Events.list_transverse_teams())
  end

  defp type_label(type), do: Map.get(@type_labels, type, type)

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :transverse_types, Crew.transverse_types())

    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Équipes transverses
        <:subtitle>{length(@teams)} équipe{if length(@teams) != 1, do: "s"}</:subtitle>
        <:actions>
          <button class="btn btn-primary btn-sm" phx-click="show_form">
            + Créer une équipe
          </button>
        </:actions>
      </.header>

      <%!-- Creation form --%>
      <%= if @show_form do %>
        <div class="card bg-base-200 mt-6" id="team-form-card">
          <div class="card-body">
            <h3 class="card-title">Créer une équipe transverse</h3>
            <.form
              for={@form}
              id="transverse-team-form"
              phx-change="validate_team"
              phx-submit="create_team"
            >
              <div class="space-y-4">
                <.input field={@form[:name]} type="text" label="Nom de l'équipe" />
                <div class="form-control">
                  <label class="label"><span class="label-text">Type / Fonction</span></label>
                  <select
                    name={@form[:transverse_type].name}
                    id={@form[:transverse_type].id}
                    class="select select-bordered"
                  >
                    <option value="">Choisir un type...</option>
                    <%= for type <- @transverse_types do %>
                      <option
                        value={type}
                        selected={
                          Phoenix.HTML.Form.normalize_value(
                            "select",
                            @form[:transverse_type].value
                          ) == type
                        }
                      >
                        {type_label(type)}
                      </option>
                    <% end %>
                  </select>
                </div>
                <.input field={@form[:description]} type="textarea" label="Description" />
                <div class="flex gap-2">
                  <.button variant="primary" phx-disable-with="Création...">Créer</.button>
                  <button type="button" class="btn btn-ghost" phx-click="cancel_form">
                    Annuler
                  </button>
                </div>
              </div>
            </.form>
          </div>
        </div>
      <% end %>

      <div class="mt-6 overflow-x-auto">
        <table class="table table-sm" id="transverse-teams-table">
          <thead>
            <tr>
              <th>Nom</th>
              <th>Type</th>
              <th>Membres</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <%= for entry <- @teams do %>
              <tr id={"team-#{entry.team.id}"}>
                <td class="font-medium">{entry.team.name}</td>
                <td>
                  <span class="badge badge-ghost badge-sm">
                    {type_label(entry.team.transverse_type)}
                  </span>
                </td>
                <td>{entry.member_count}</td>
                <td class="flex gap-1">
                  <.link
                    navigate={~p"/admin/equipes-transverses/#{entry.team.id}"}
                    class="btn btn-ghost btn-xs"
                  >
                    Voir
                  </.link>
                  <button
                    class="btn btn-ghost btn-xs text-error"
                    phx-click="delete_team"
                    phx-value-id={entry.team.id}
                    data-confirm={"Supprimer l'équipe \"#{entry.team.name}\" ?"}
                  >
                    Supprimer
                  </button>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </Layouts.app>
    """
  end
end
