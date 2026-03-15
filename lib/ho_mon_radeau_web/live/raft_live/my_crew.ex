defmodule HoMonRadeauWeb.RaftLive.MyCrew do
  use HoMonRadeauWeb, :live_view

  alias HoMonRadeau.Events
  alias HoMonRadeau.Events.{CrewMember, RaftLink}
  alias HoMonRadeau.Accounts
  alias HoMonRadeau.Drums
  alias HoMonRadeau.CUF

  @role_labels %{
    "captain" => "Capitaine",
    "lead_construction" => "Lead construction",
    "cooking" => "Cuisine",
    "safe_contact" => "Interlocuteur SAFE",
    "logistics" => "Logistique",
    "music" => "Musique",
    "decoration" => "Décoration",
    "other" => "Autre"
  }

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
        my_member = Events.get_crew_member(crew.id, user.id)

        {:ok,
         socket
         |> assign(:my_member, my_member)
         |> assign(:crew, crew)
         |> assign(:editing_info, false)
         |> load_crew_data()}
    end
  end

  # -- Edit raft info --

  @impl true
  def handle_event("edit_info", _params, socket) do
    changeset = Events.change_raft(socket.assigns.raft)

    {:noreply,
     socket
     |> assign(:editing_info, true)
     |> assign(:edit_form, to_form(changeset))}
  end

  @impl true
  def handle_event("cancel_edit_info", _params, socket) do
    {:noreply, assign(socket, :editing_info, false)}
  end

  @impl true
  def handle_event("validate_info", %{"raft" => params}, socket) do
    changeset =
      socket.assigns.raft
      |> Events.change_raft(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :edit_form, to_form(changeset))}
  end

  @impl true
  def handle_event("save_info", %{"raft" => params}, socket) do
    case Events.update_raft(socket.assigns.raft, params) do
      {:ok, _raft} ->
        {:noreply,
         socket
         |> assign(:editing_info, false)
         |> put_flash(:info, "Informations mises à jour.")
         |> load_crew_data()}

      {:error, changeset} ->
        {:noreply, assign(socket, :edit_form, to_form(changeset))}
    end
  end

  # -- Join requests --

  @impl true
  def handle_event("accept_request", %{"id" => id}, socket) do
    request = Events.get_join_request!(id)
    user = socket.assigns.current_scope.user

    case Events.accept_join_request(request, user) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "#{Accounts.display_name(request.user)} a rejoint l'équipage !")
         |> load_crew_data()}

      {:error, :user_not_validated} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Cet utilisateur doit d'abord être validé par l'équipe d'accueil."
         )}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de l'acceptation.")}
    end
  end

  @impl true
  def handle_event("reject_request", %{"id" => id}, socket) do
    request = Events.get_join_request!(id)
    user = socket.assigns.current_scope.user

    case Events.reject_join_request(request, user) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Demande refusée.")
         |> load_crew_data()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors du refus.")}
    end
  end

  # -- Roles --

  @impl true
  def handle_event("save_my_roles", %{"roles" => roles}, socket) do
    selected_roles = for {role, "true"} <- roles, do: role

    case Events.update_member_roles(socket.assigns.my_member, selected_roles) do
      {:ok, updated_member} ->
        {:noreply,
         socket
         |> assign(:my_member, updated_member)
         |> put_flash(:info, "Rôles mis à jour.")
         |> load_crew_data()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de la mise à jour des rôles.")}
    end
  end

  @impl true
  def handle_event("save_my_roles", _params, socket) do
    case Events.update_member_roles(socket.assigns.my_member, []) do
      {:ok, updated_member} ->
        {:noreply,
         socket
         |> assign(:my_member, updated_member)
         |> put_flash(:info, "Rôles mis à jour.")
         |> load_crew_data()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de la mise à jour des rôles.")}
    end
  end

  # -- Captain & manager --

  @impl true
  def handle_event("set_captain", %{"user-id" => user_id}, socket) do
    crew = socket.assigns.crew

    case Events.set_captain(crew.id, String.to_integer(user_id)) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Capitaine mis à jour.")
         |> load_crew_data()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de la nomination du capitaine.")}
    end
  end

  @impl true
  def handle_event("remove_captain", _params, socket) do
    crew = socket.assigns.crew
    Events.remove_captain(crew.id)

    {:noreply,
     socket
     |> put_flash(:info, "Rôle de capitaine retiré.")
     |> load_crew_data()}
  end

  @impl true
  def handle_event("promote_manager", %{"user-id" => user_id}, socket) do
    crew = socket.assigns.crew

    case Events.promote_to_manager(crew.id, String.to_integer(user_id)) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Membre promu gestionnaire.")
         |> load_crew_data()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de la promotion.")}
    end
  end

  @impl true
  def handle_event("demote_manager", %{"user-id" => user_id}, socket) do
    crew = socket.assigns.crew

    case Events.demote_from_manager(crew.id, String.to_integer(user_id)) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Rôle de gestionnaire retiré.")
         |> load_crew_data()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de la rétrogradation.")}
    end
  end

  # -- Leave / remove --

  @impl true
  def handle_event("leave_crew", _params, socket) do
    user = socket.assigns.current_scope.user
    crew = socket.assigns.crew

    case Events.leave_crew(user.id, crew.id) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Vous avez quitté l'équipage.")
         |> redirect(to: ~p"/radeaux")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors du départ.")}
    end
  end

  @impl true
  def handle_event("remove_member", %{"user-id" => user_id}, socket) do
    crew = socket.assigns.crew
    current_user = socket.assigns.current_scope.user

    case Events.leave_crew(String.to_integer(user_id), crew.id, removed_by_id: current_user.id) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Membre retiré de l'équipage.")
         |> load_crew_data()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors du retrait.")}
    end
  end

  # -- CUF --

  @impl true
  def handle_event("submit_cuf", %{"participants" => participants}, socket) do
    crew = socket.assigns.crew
    selected_ids = for {id, "true"} <- participants, do: String.to_integer(id)

    case CUF.create_declaration(crew.id, selected_ids) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Déclaration CUF enregistrée.")
         |> load_crew_data()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de la déclaration.")}
    end
  end

  @impl true
  def handle_event("submit_cuf", _params, socket) do
    {:noreply, put_flash(socket, :error, "Veuillez sélectionner au moins un participant.")}
  end

  # -- Drums --

  @impl true
  def handle_event("validate_drums", %{"drum_request" => params}, socket) do
    changeset =
      Drums.change_drum_request(
        socket.assigns.pending_drum_request || %Drums.DrumRequest{},
        params
      )
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :drum_form, to_form(changeset))}
  end

  @impl true
  def handle_event("submit_drums", %{"drum_request" => params}, socket) do
    crew = socket.assigns.crew
    pending = socket.assigns.pending_drum_request

    result =
      if pending do
        Drums.update_drum_request(pending, params)
      else
        Drums.create_drum_request(crew.id, params)
      end

    case result do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Demande de bidons enregistrée.")
         |> load_crew_data()}

      {:error, :already_paid} ->
        {:noreply, put_flash(socket, :error, "Cette demande est déjà payée.")}

      {:error, changeset} ->
        {:noreply, assign(socket, :drum_form, to_form(changeset))}
    end
  end

  # -- Links --

  @impl true
  def handle_event("add_link", _params, socket) do
    changeset = Events.change_raft_link(%RaftLink{raft_id: socket.assigns.raft.id})
    {:noreply, assign(socket, :link_form, to_form(changeset))}
  end

  @impl true
  def handle_event("cancel_link", _params, socket) do
    {:noreply, assign(socket, :link_form, nil)}
  end

  @impl true
  def handle_event("validate_link", %{"raft_link" => params}, socket) do
    changeset =
      %RaftLink{raft_id: socket.assigns.raft.id}
      |> Events.change_raft_link(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :link_form, to_form(changeset))}
  end

  @impl true
  def handle_event("save_link", %{"raft_link" => params}, socket) do
    params = Map.put(params, "raft_id", socket.assigns.raft.id)

    case Events.create_raft_link(params) do
      {:ok, _link} ->
        {:noreply,
         socket
         |> assign(:link_form, nil)
         |> put_flash(:info, "Lien ajouté.")
         |> load_crew_data()}

      {:error, changeset} ->
        {:noreply, assign(socket, :link_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("delete_link", %{"id" => id}, socket) do
    link = Enum.find(socket.assigns.raft_links, &(&1.id == String.to_integer(id)))

    if link do
      Events.delete_raft_link(link)

      {:noreply,
       socket
       |> put_flash(:info, "Lien supprimé.")
       |> load_crew_data()}
    else
      {:noreply, socket}
    end
  end

  # -- Data loading --

  defp load_crew_data(socket) do
    crew = socket.assigns.crew
    user = socket.assigns.current_scope.user
    raft = Events.get_raft!(crew.raft_id) |> Events.preload_raft_details()
    is_manager = Events.is_crew_manager?(crew, user)
    pending_requests = if is_manager, do: Events.list_pending_join_requests(crew), else: []
    captain = Events.get_captain(crew.id)
    roles_summary = Events.get_roles_summary(crew.id)
    drums_summary = Drums.get_crew_summary(crew.id)
    pending_drum = Drums.get_pending_request(crew.id)
    drum_settings = Drums.get_settings()
    drum_form = to_form(Drums.change_drum_request(pending_drum || %Drums.DrumRequest{}))
    cuf_summary = CUF.get_crew_cuf_summary(crew.id)
    cuf_settings = CUF.get_settings()
    my_member = Events.get_crew_member(crew.id, user.id)
    is_captain = my_member && my_member.is_captain

    socket
    |> assign(:page_title, "Mon radeau - #{raft.name}")
    |> assign(:raft, raft)
    |> assign(:is_manager, is_manager)
    |> assign(:pending_requests, pending_requests)
    |> assign(:captain, captain)
    |> assign(:roles_summary, roles_summary)
    |> assign(:drums_summary, drums_summary)
    |> assign(:pending_drum_request, pending_drum)
    |> assign(:drum_settings, drum_settings)
    |> assign(:drum_form, drum_form)
    |> assign(:cuf_summary, cuf_summary)
    |> assign(:cuf_settings, cuf_settings)
    |> assign(:my_member, my_member)
    |> assign(:is_captain, is_captain)
    |> assign(:raft_links, Events.list_raft_links(raft.id))
    |> assign_new(:link_form, fn -> nil end)
  end

  defp role_label(role), do: Map.get(@role_labels, role, role)

  # -- Render --

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(:available_roles, CrewMember.valid_roles())
      |> assign(:required_roles, CrewMember.required_roles())
      |> assign(:optional_roles, CrewMember.optional_roles())

    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <%!-- ===== HEADER ===== --%>
      <div class="flex items-start justify-between gap-4">
        <div>
          <h1 class="text-2xl font-bold text-slate-900">{@raft.name}</h1>
          <%= if @raft.description_short do %>
            <p class="text-slate-500 mt-1">{@raft.description_short}</p>
          <% end %>
          <div class="flex items-center gap-2 mt-2">
            <%= if @raft.validated do %>
              <span class="bg-green-100 text-green-700 text-xs font-medium px-2.5 py-0.5 rounded-full inline-flex items-center gap-1">
                <.icon name="hero-check-circle-mini" class="size-3.5" /> Validé
              </span>
            <% else %>
              <span class="bg-slate-100 text-slate-600 text-xs font-medium px-2.5 py-0.5 rounded-full">
                En attente de validation
              </span>
            <% end %>
            <span class="text-xs text-slate-400">
              {length(@raft.crew.crew_members)} membre{if length(@raft.crew.crew_members) > 1, do: "s"}
            </span>
          </div>
        </div>
        <%= if @is_manager do %>
          <button
            phx-click="edit_info"
            class="text-sm text-slate-600 hover:bg-slate-50 rounded-lg px-3 py-1.5 font-medium transition inline-flex items-center gap-1"
          >
            <.icon name="hero-pencil-square-mini" class="size-4" /> Modifier
          </button>
        <% end %>
      </div>

      <div class="mt-8 grid gap-8 lg:grid-cols-3">
        <div class="lg:col-span-2 space-y-6">
          <%!-- ===== PENDING JOIN REQUESTS ===== --%>
          <%= if @is_manager && length(@pending_requests) > 0 do %>
            <div class="bg-amber-50 border border-amber-200 rounded-xl">
              <div class="p-6">
                <h3 class="text-lg font-semibold text-amber-700">
                  Demandes d'adhésion ({length(@pending_requests)})
                </h3>
                <div class="space-y-4 mt-2">
                  <%= for request <- @pending_requests do %>
                    <div class="flex items-start justify-between gap-4 p-3 bg-white rounded-lg">
                      <div>
                        <p class="font-medium">{Accounts.display_name(request.user)}</p>
                        <%= if request.user.validated do %>
                          <span class="bg-green-100 text-green-700 text-xs font-medium px-2 py-0.5 rounded-full">
                            Validé·e
                          </span>
                        <% else %>
                          <span class="bg-amber-100 text-amber-700 text-xs font-medium px-2 py-0.5 rounded-full">
                            En attente validation
                          </span>
                        <% end %>
                        <%= if request.message do %>
                          <p class="text-sm text-slate-500 mt-1 italic">
                            "{request.message}"
                          </p>
                        <% end %>
                        <p class="text-xs text-slate-400 mt-1">
                          Demande envoyée le {Calendar.strftime(
                            request.inserted_at,
                            "%d/%m/%Y à %H:%M"
                          )}
                        </p>
                      </div>
                      <div class="flex gap-2">
                        <%= if request.user.validated do %>
                          <button
                            class="bg-green-600 text-white rounded-lg px-3 py-1.5 text-sm font-medium hover:bg-green-700 transition"
                            phx-click="accept_request"
                            phx-value-id={request.id}
                          >
                            Accepter
                          </button>
                        <% end %>
                        <button
                          class="text-sm text-slate-600 hover:bg-slate-50 rounded-lg px-3 py-1.5 font-medium transition"
                          phx-click="reject_request"
                          phx-value-id={request.id}
                          data-confirm="Êtes-vous sûr·e de vouloir refuser cette demande ?"
                        >
                          Refuser
                        </button>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
          <% end %>

          <%!-- ===== INFOS & DESCRIPTION ===== --%>
          <div class="bg-white rounded-xl shadow-sm border border-slate-200">
            <div class="p-6">
              <%= if @editing_info do %>
                <h3 class="text-lg font-semibold text-slate-900 mb-4">Modifier les informations</h3>
                <.form
                  for={@edit_form}
                  id="edit-raft-form"
                  phx-change="validate_info"
                  phx-submit="save_info"
                  class="space-y-4"
                >
                  <.input
                    field={@edit_form[:description_short]}
                    type="text"
                    label="Description courte"
                    placeholder="Une phrase pour décrire votre équipage..."
                    maxlength="150"
                  />
                  <.input
                    field={@edit_form[:description]}
                    type="textarea"
                    label="Description complète"
                    rows="4"
                  />
                  <.input
                    field={@edit_form[:forum_url]}
                    type="url"
                    label="Lien forum"
                    placeholder="https://..."
                  />
                  <div class="flex gap-3 pt-2">
                    <button
                      type="submit"
                      class="bg-indigo-600 text-white rounded-lg px-4 py-2 text-sm font-medium hover:bg-indigo-700 transition"
                      phx-disable-with="Enregistrement..."
                    >
                      Enregistrer
                    </button>
                    <button
                      type="button"
                      phx-click="cancel_edit_info"
                      class="text-slate-600 hover:bg-slate-50 rounded-lg px-4 py-2 text-sm font-medium transition"
                    >
                      Annuler
                    </button>
                  </div>
                </.form>
              <% else %>
                <%= if @raft.description do %>
                  <p class="whitespace-pre-wrap text-slate-700">{@raft.description}</p>
                <% else %>
                  <p class="text-slate-400 italic">Aucune description.</p>
                <% end %>
                <%= if @raft.forum_url do %>
                  <div class="mt-3">
                    <a
                      href={@raft.forum_url}
                      target="_blank"
                      class="text-sm text-indigo-600 hover:underline inline-flex items-center gap-1"
                    >
                      <.icon name="hero-chat-bubble-left-right-mini" class="size-4" />
                      Discussion forum
                    </a>
                  </div>
                <% end %>
              <% end %>
            </div>
          </div>

          <%!-- ===== LIENS ===== --%>
          <div class="bg-white rounded-xl shadow-sm border border-slate-200">
            <div class="p-6">
              <div class="flex items-center justify-between mb-3">
                <h3 class="text-lg font-semibold text-slate-900">Liens</h3>
                <%= if @is_manager && is_nil(@link_form) do %>
                  <button
                    phx-click="add_link"
                    class="text-sm text-indigo-600 hover:text-indigo-700 font-medium inline-flex items-center gap-1"
                  >
                    <.icon name="hero-plus-mini" class="size-4" /> Ajouter
                  </button>
                <% end %>
              </div>

              <%!-- Existing links --%>
              <%= if @raft_links == [] && is_nil(@link_form) do %>
                <p class="text-sm text-slate-400 italic">Aucun lien.</p>
              <% end %>
              <%= for link <- @raft_links do %>
                <div class="flex items-center justify-between py-2 group/link">
                  <a
                    href={link.url}
                    target="_blank"
                    class="text-sm text-indigo-600 hover:underline inline-flex items-center gap-1.5 min-w-0"
                  >
                    <.icon name="hero-arrow-top-right-on-square-mini" class="size-4 shrink-0" />
                    <span class="truncate">{link.title}</span>
                  </a>
                  <div class="flex items-center gap-2 shrink-0 ml-2">
                    <span class={[
                      "text-xs px-1.5 py-0.5 rounded-full",
                      if(link.is_public,
                        do: "bg-green-100 text-green-700",
                        else: "bg-slate-100 text-slate-500"
                      )
                    ]}>
                      {if link.is_public, do: "public", else: "privé"}
                    </span>
                    <%= if @is_manager do %>
                      <button
                        phx-click="delete_link"
                        phx-value-id={link.id}
                        data-confirm={"Supprimer le lien \"#{link.title}\" ?"}
                        class="text-slate-400 hover:text-red-600 opacity-0 group-hover/link:opacity-100 transition"
                      >
                        <.icon name="hero-x-mark-mini" class="size-4" />
                      </button>
                    <% end %>
                  </div>
                </div>
              <% end %>

              <%!-- Add link form --%>
              <%= if @link_form do %>
                <div class="border-t border-slate-100 pt-3 mt-3">
                  <.form
                    for={@link_form}
                    id="add-link-form"
                    phx-change="validate_link"
                    phx-submit="save_link"
                    class="space-y-3"
                  >
                    <div class="grid grid-cols-2 gap-3">
                      <.input
                        field={@link_form[:title]}
                        type="text"
                        label="Titre"
                        placeholder="Forum, Drive..."
                      />
                      <.input
                        field={@link_form[:url]}
                        type="url"
                        label="URL"
                        placeholder="https://..."
                      />
                    </div>
                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        name="raft_link[is_public]"
                        value="true"
                        checked={
                          Phoenix.HTML.Form.normalize_value("checkbox", @link_form[:is_public].value)
                        }
                        class="w-4 h-4 rounded border-slate-300 text-indigo-600 focus:ring-indigo-500"
                      />
                      <span class="text-sm text-slate-700">
                        Visible sur la page publique du radeau
                      </span>
                    </label>
                    <div class="flex gap-2">
                      <button
                        type="submit"
                        class="bg-indigo-600 text-white rounded-lg px-4 py-2 text-sm font-medium hover:bg-indigo-700 transition"
                        phx-disable-with="Ajout..."
                      >
                        Ajouter
                      </button>
                      <button
                        type="button"
                        phx-click="cancel_link"
                        class="text-slate-600 hover:bg-slate-50 rounded-lg px-4 py-2 text-sm font-medium transition"
                      >
                        Annuler
                      </button>
                    </div>
                  </.form>
                </div>
              <% end %>
            </div>
          </div>

          <%!-- ===== RÔLES (collapsible) ===== --%>
          <details
            class="bg-white rounded-xl shadow-sm border border-slate-200 group"
            id="roles-section"
          >
            <summary class="p-6 cursor-pointer select-none flex items-center justify-between">
              <div class="flex items-center gap-3">
                <h3 class="text-lg font-semibold text-slate-900">Rôles</h3>
                <% unfilled_count =
                  Enum.count(@required_roles, fn r -> @roles_summary[r] == [] end) +
                    if(is_nil(@captain), do: 1, else: 0) %>
                <%= if unfilled_count > 0 do %>
                  <span class="bg-amber-100 text-amber-700 text-xs font-medium px-2 py-0.5 rounded-full">
                    {unfilled_count} à pourvoir
                  </span>
                <% else %>
                  <span class="bg-green-100 text-green-700 text-xs font-medium px-2 py-0.5 rounded-full">
                    Complet
                  </span>
                <% end %>
              </div>
              <.icon
                name="hero-chevron-down-mini"
                class="size-5 text-slate-400 transition-transform group-open:rotate-180"
              />
            </summary>
            <div class="px-6 pb-6 border-t border-slate-100 pt-4 space-y-6">
              <%!-- Roles summary --%>
              <div>
                <h4 class="text-sm font-semibold text-slate-500 mb-2">État des rôles</h4>
                <div class="space-y-1">
                  <%!-- Captain --%>
                  <%= if @captain do %>
                    <div class="flex items-center gap-2 text-sm">
                      <.icon name="hero-check-circle-mini" class="size-4 text-green-600" />
                      <span class="font-medium">Capitaine :</span>
                      <span>{Accounts.display_name(@captain.user)}</span>
                    </div>
                  <% else %>
                    <div class="flex items-center gap-2 text-sm text-amber-600">
                      <.icon name="hero-exclamation-triangle-mini" class="size-4" />
                      <span class="font-medium">Capitaine</span>
                    </div>
                  <% end %>
                  <%!-- Other roles --%>
                  <%= for role <- @available_roles do %>
                    <%= if @roles_summary[role] != [] do %>
                      <div class="flex items-center gap-2 text-sm">
                        <.icon name="hero-check-circle-mini" class="size-4 text-green-600" />
                        <span class="font-medium">{role_label(role)} :</span>
                        <span>{Enum.join(@roles_summary[role], ", ")}</span>
                      </div>
                    <% else %>
                      <div class="flex items-center gap-2 text-sm text-slate-400">
                        <.icon name="hero-minus-circle-mini" class="size-4" />
                        <span>
                          {role_label(role)}
                          <%= if role in @required_roles do %>
                            <span class="text-amber-500 text-xs">(requis)</span>
                          <% end %>
                        </span>
                      </div>
                    <% end %>
                  <% end %>
                </div>
              </div>

              <%!-- My roles --%>
              <div class="border-t border-slate-100 pt-4">
                <h4 class="text-sm font-semibold text-slate-500 mb-2">Mes rôles</h4>
                <form phx-submit="save_my_roles" id="my-roles-form">
                  <div class="flex flex-wrap gap-x-4 gap-y-2">
                    <%= for role <- @available_roles do %>
                      <label class="flex items-center gap-2 cursor-pointer">
                        <input
                          type="checkbox"
                          name={"roles[#{role}]"}
                          value="true"
                          checked={role in (@my_member.roles || [])}
                          class="w-4 h-4 rounded border-slate-300 text-indigo-600 focus:ring-indigo-500"
                        />
                        <span class="text-sm text-slate-700">{role_label(role)}</span>
                      </label>
                    <% end %>
                  </div>
                  <p class="text-xs text-slate-400 mt-2">
                    Le rôle de capitaine est attribué par les gestionnaires.
                  </p>
                  <div class="mt-3">
                    <button
                      type="submit"
                      class="bg-indigo-600 text-white rounded-lg px-4 py-2 text-sm font-medium hover:bg-indigo-700 transition"
                      phx-disable-with="Enregistrement..."
                    >
                      Enregistrer mes rôles
                    </button>
                  </div>
                </form>
              </div>
            </div>
          </details>

          <%!-- ===== FINANCES (collapsible) ===== --%>
          <details
            class="bg-white rounded-xl shadow-sm border border-slate-200 group"
            id="finances-section"
          >
            <summary class="p-6 cursor-pointer select-none flex items-center justify-between">
              <div class="flex items-center gap-3">
                <h3 class="text-lg font-semibold text-slate-900">Finances</h3>
                <div class="flex gap-2">
                  <span class="text-xs text-slate-500">
                    Bidons : {if @drums_summary.total_paid_quantity > 0,
                      do: "#{@drums_summary.total_paid_quantity} payés",
                      else: "—"}
                  </span>
                  <span class="text-xs text-slate-300">·</span>
                  <span class="text-xs text-slate-500">
                    CUF : {if @cuf_summary.total_validated_amount > 0,
                      do: "#{@cuf_summary.total_validated_amount} €",
                      else: "—"}
                  </span>
                </div>
              </div>
              <.icon
                name="hero-chevron-down-mini"
                class="size-5 text-slate-400 transition-transform group-open:rotate-180"
              />
            </summary>
            <div class="px-6 pb-6 border-t border-slate-100 pt-4 space-y-6">
              <%!-- Drums --%>
              <div>
                <h4 class="text-sm font-semibold text-slate-500 mb-2">Bidons</h4>
                <%= if @drums_summary.requests != [] do %>
                  <div class="space-y-1 mb-3">
                    <%= for req <- @drums_summary.requests do %>
                      <div class="flex items-center justify-between text-sm">
                        <span>
                          {req.quantity} bidons — {req.total_amount} €
                        </span>
                        <%= if req.status == "paid" do %>
                          <span class="bg-green-100 text-green-700 text-xs font-medium px-1.5 py-0.5 rounded-full">
                            Payé
                          </span>
                        <% else %>
                          <span class="bg-amber-100 text-amber-700 text-xs font-medium px-1.5 py-0.5 rounded-full">
                            En attente
                          </span>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                <% end %>
                <.form
                  for={@drum_form}
                  id="drum-request-form"
                  phx-change="validate_drums"
                  phx-submit="submit_drums"
                >
                  <div class="flex items-end gap-3">
                    <div class="flex-1">
                      <.input
                        field={@drum_form[:quantity]}
                        type="number"
                        label={
                          if @pending_drum_request,
                            do: "Modifier la demande",
                            else: "Nombre de bidons"
                        }
                        min="0"
                      />
                    </div>
                    <button
                      type="submit"
                      class="bg-indigo-600 text-white rounded-lg px-4 py-2 text-sm font-medium hover:bg-indigo-700 transition mb-0.5"
                      phx-disable-with="Envoi..."
                    >
                      {if @pending_drum_request, do: "Modifier", else: "Demander"}
                    </button>
                  </div>
                  <.input field={@drum_form[:note]} type="text" label="Note (optionnel)" />
                  <p class="text-xs text-slate-400 mt-1">
                    Tarif : {@drum_settings.unit_price} € / bidon
                    <%= if @drum_settings.rib_iban do %>
                      — IBAN : {@drum_settings.rib_iban}
                    <% end %>
                  </p>
                </.form>
              </div>

              <%!-- CUF --%>
              <div class="border-t border-slate-100 pt-4">
                <h4 class="text-sm font-semibold text-slate-500 mb-2">
                  CUF (Cotisation Urbaine Flottante)
                </h4>
                <div class="space-y-1 text-sm">
                  <p>
                    Participants validés :
                    <span class="font-medium">{@cuf_summary.total_validated_participants}</span>
                    — Montant :
                    <span class="font-medium">{@cuf_summary.total_validated_amount} €</span>
                  </p>
                  <%= if @cuf_summary.pending do %>
                    <div class="bg-amber-50 border border-amber-200 text-amber-800 rounded-lg p-3 flex items-start gap-2 text-sm mt-2">
                      <.icon name="hero-clock-mini" class="size-4 mt-0.5" />
                      <span>
                        Déclaration en attente : {@cuf_summary.pending.participant_count} participants
                        ({@cuf_summary.pending.total_amount} €)
                      </span>
                    </div>
                  <% end %>
                </div>
                <%= if @is_captain do %>
                  <div class="mt-3">
                    <form phx-submit="submit_cuf" id="cuf-declaration-form">
                      <h5 class="text-sm font-medium mb-2">Déclarer les participants</h5>
                      <div class="flex flex-wrap gap-x-4 gap-y-1">
                        <%= for member <- @raft.crew.crew_members do %>
                          <label class="flex items-center gap-2 cursor-pointer">
                            <input
                              type="checkbox"
                              name={"participants[#{member.user_id}]"}
                              value="true"
                              checked={
                                member.user_id in ((@cuf_summary.pending &&
                                                      @cuf_summary.pending.participant_user_ids) || [])
                              }
                              class="w-4 h-4 rounded border-slate-300 text-indigo-600 focus:ring-indigo-500"
                            />
                            <span class="text-sm text-slate-700">
                              {Accounts.display_name(member.user)}
                              <%= unless member.user.validated do %>
                                <span class="text-amber-600 text-xs">(non validé)</span>
                              <% end %>
                            </span>
                          </label>
                        <% end %>
                      </div>
                      <p class="text-xs text-slate-400 mt-2">
                        Montant : {@cuf_settings.unit_price} € / personne
                        <%= if @cuf_settings.rib_iban do %>
                          — IBAN : {@cuf_settings.rib_iban}
                        <% end %>
                      </p>
                      <div class="mt-3">
                        <button
                          type="submit"
                          class="bg-indigo-600 text-white rounded-lg px-4 py-2 text-sm font-medium hover:bg-indigo-700 transition"
                          phx-disable-with="Envoi..."
                        >
                          Soumettre la déclaration
                        </button>
                      </div>
                    </form>
                  </div>
                <% end %>
              </div>
            </div>
          </details>

          <%!-- ===== BOTTOM LINKS ===== --%>
          <div class="flex flex-wrap items-center justify-between gap-4 pt-2">
            <div class="flex flex-wrap gap-3 text-sm">
              <.link
                navigate={~p"/radeaux/#{@raft.slug}"}
                class="text-slate-500 hover:text-indigo-600 transition inline-flex items-center gap-1"
              >
                <.icon name="hero-eye-mini" class="size-4" /> Page publique
              </.link>
              <span class="text-slate-300">·</span>
              <.link
                navigate={~p"/fiche-inscription"}
                class="text-slate-500 hover:text-indigo-600 transition inline-flex items-center gap-1"
              >
                <.icon name="hero-document-text-mini" class="size-4" /> Ma fiche d'inscription
              </.link>
              <%= if @raft.forum_url do %>
                <span class="text-slate-300">·</span>
                <a
                  href={@raft.forum_url}
                  target="_blank"
                  class="text-slate-500 hover:text-indigo-600 transition inline-flex items-center gap-1"
                >
                  <.icon name="hero-chat-bubble-left-right-mini" class="size-4" /> Forum
                </a>
              <% end %>
            </div>
            <button
              class="text-sm text-red-600 hover:bg-red-50 rounded-lg px-3 py-1.5 font-medium transition"
              phx-click="leave_crew"
              data-confirm={
                if(@is_captain,
                  do:
                    "Vous êtes le capitaine. En quittant, le rôle sera retiré. Quitter quand même ?",
                  else: "Voulez-vous vraiment quitter l'équipage ?"
                )
              }
              id="leave-crew-btn"
            >
              Quitter l'équipage
            </button>
          </div>
        </div>

        <%!-- ===== CREW MEMBERS SIDEBAR ===== --%>
        <div>
          <div class="bg-white rounded-xl shadow-sm border border-slate-200">
            <div class="p-6">
              <h3 class="text-lg font-semibold text-slate-900">
                Équipage
                <span class="bg-slate-100 text-slate-600 text-xs font-medium px-2.5 py-0.5 rounded-full">
                  {length(@raft.crew.crew_members)}
                </span>
              </h3>

              <ul class="space-y-4 mt-2" id="crew-members-list">
                <%= for member <- @raft.crew.crew_members do %>
                  <li class="p-3 bg-white rounded-lg">
                    <div class="flex items-center justify-between">
                      <div>
                        <p class="font-medium">{Accounts.display_name(member.user)}</p>
                        <div class="flex flex-wrap gap-1 mt-1">
                          <%= if member.is_captain do %>
                            <span class="bg-indigo-100 text-indigo-700 text-xs font-medium px-1.5 py-0.5 rounded-full">
                              Capitaine ★
                            </span>
                          <% end %>
                          <%= if member.is_manager do %>
                            <span class="bg-indigo-100 text-indigo-600 text-xs font-medium px-1.5 py-0.5 rounded-full">
                              Gestionnaire
                            </span>
                          <% end %>
                          <%= for role <- member.roles || [] do %>
                            <span class="bg-slate-100 text-slate-600 text-xs font-medium px-1.5 py-0.5 rounded-full">
                              {role_label(role)}
                            </span>
                          <% end %>
                        </div>
                      </div>
                    </div>
                    <%!-- Manager actions --%>
                    <%= if @is_manager do %>
                      <div class="flex flex-wrap gap-1 mt-2 pt-2 border-t border-slate-100">
                        <%= if member.is_captain do %>
                          <button
                            class="text-xs text-slate-600 hover:bg-slate-50 rounded-md px-2 py-1 font-medium transition"
                            phx-click="remove_captain"
                            data-confirm="Retirer le rôle de capitaine ?"
                          >
                            Retirer capitaine
                          </button>
                        <% else %>
                          <button
                            class="text-xs text-slate-600 hover:bg-slate-50 rounded-md px-2 py-1 font-medium transition"
                            phx-click="set_captain"
                            phx-value-user-id={member.user_id}
                            data-confirm={
                              if(@captain,
                                do:
                                  "Attention : #{Accounts.display_name(@captain.user)} est actuellement capitaine. Cette action lui retirera ce rôle. Continuer ?",
                                else: "Nommer #{Accounts.display_name(member.user)} capitaine ?"
                              )
                            }
                          >
                            Nommer capitaine
                          </button>
                        <% end %>
                        <%= if member.user_id != @current_scope.user.id do %>
                          <%= if member.is_manager do %>
                            <button
                              class="text-xs text-slate-600 hover:bg-slate-50 rounded-md px-2 py-1 font-medium transition"
                              phx-click="demote_manager"
                              phx-value-user-id={member.user_id}
                              data-confirm="Retirer le rôle de gestionnaire ?"
                            >
                              Retirer gestionnaire
                            </button>
                          <% else %>
                            <button
                              class="text-xs text-slate-600 hover:bg-slate-50 rounded-md px-2 py-1 font-medium transition"
                              phx-click="promote_manager"
                              phx-value-user-id={member.user_id}
                            >
                              Nommer gestionnaire
                            </button>
                          <% end %>
                          <button
                            class="text-xs text-red-600 hover:bg-red-50 rounded-md px-2 py-1 font-medium transition"
                            phx-click="remove_member"
                            phx-value-user-id={member.user_id}
                            data-confirm={"Retirer #{Accounts.display_name(member.user)} de l'équipage ?"}
                          >
                            Retirer
                          </button>
                        <% end %>
                      </div>
                    <% end %>
                  </li>
                <% end %>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
