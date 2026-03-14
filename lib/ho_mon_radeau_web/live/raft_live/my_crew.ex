defmodule HoMonRadeauWeb.RaftLive.MyCrew do
  use HoMonRadeauWeb, :live_view

  alias HoMonRadeau.Events
  alias HoMonRadeau.Events.CrewMember
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
         |> load_crew_data()}
    end
  end

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
    # No roles selected at all
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
  end

  defp role_label(role), do: Map.get(@role_labels, role, role)

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(:available_roles, CrewMember.valid_roles())
      |> assign(:required_roles, CrewMember.required_roles())
      |> assign(:optional_roles, CrewMember.optional_roles())

    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@raft.name}
        <:subtitle>Page équipage</:subtitle>
        <:actions>
          <.link
            navigate={~p"/radeaux/#{@raft.slug}"}
            class="text-sm text-slate-600 hover:bg-slate-50 rounded-lg px-3 py-1.5 font-medium transition"
          >
            Voir la page publique
          </.link>
        </:actions>
      </.header>

      <div class="mt-8 grid gap-8 lg:grid-cols-3">
        <div class="lg:col-span-2 space-y-8">
          <%!-- Pending join requests (managers only) --%>
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

          <%!-- Roles summary --%>
          <div class="bg-white rounded-xl shadow-sm border border-slate-200" id="roles-summary">
            <div class="p-6">
              <h3 class="text-lg font-semibold text-slate-900">État des rôles</h3>

              <%!-- À pourvoir (required roles that are unfilled) --%>
              <% unfilled_required = Enum.filter(@required_roles, fn r -> @roles_summary[r] == [] end)

              unfilled_required =
                if(is_nil(@captain), do: ["captain" | unfilled_required], else: unfilled_required) %>
              <%= if unfilled_required != [] do %>
                <div class="mt-3">
                  <h4 class="text-sm font-semibold text-amber-600 mb-1">À pourvoir</h4>
                  <div class="space-y-1">
                    <%= for role <- unfilled_required do %>
                      <div class="flex items-center gap-2 text-amber-600">
                        <.icon name="hero-exclamation-triangle-mini" class="size-4" />
                        <span class="font-medium">{role_label(role)}</span>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>

              <%!-- Rôles actuels (filled roles) --%>
              <% filled = Enum.filter(@available_roles, fn r -> @roles_summary[r] != [] end)
              filled = if(@captain, do: ["captain" | filled], else: filled) %>
              <%= if filled != [] do %>
                <div class="mt-3">
                  <h4 class="text-sm font-semibold text-green-600 mb-1">Rôles actuels</h4>
                  <div class="space-y-1">
                    <%= for role <- filled do %>
                      <div class="flex items-center gap-2">
                        <.icon name="hero-check-circle-mini" class="size-4 text-green-600" />
                        <span class="font-medium">{role_label(role)} :</span>
                        <span>
                          <%= if role == "captain" do %>
                            {Accounts.display_name(@captain.user)}
                          <% else %>
                            {Enum.join(@roles_summary[role], ", ")}
                          <% end %>
                        </span>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>

              <%!-- Optionnels (optional roles that are unfilled) --%>
              <% unfilled_optional = Enum.filter(@optional_roles, fn r -> @roles_summary[r] == [] end) %>
              <%= if unfilled_optional != [] do %>
                <div class="mt-3">
                  <h4 class="text-sm font-semibold text-slate-400 mb-1">Optionnels</h4>
                  <div class="space-y-1">
                    <%= for role <- unfilled_optional do %>
                      <div class="flex items-center gap-2 text-slate-300">
                        <.icon name="hero-minus-circle-mini" class="size-4" />
                        <span>{role_label(role)}</span>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          </div>

          <%!-- My roles (self-declaration) --%>
          <div class="bg-white rounded-xl shadow-sm border border-slate-200" id="my-roles">
            <div class="p-6">
              <h3 class="text-lg font-semibold text-slate-900">Mon profil dans l'équipage</h3>
              <form phx-submit="save_my_roles" id="my-roles-form">
                <div class="space-y-2 mt-2">
                  <%= for role <- @available_roles do %>
                    <label class="flex items-center gap-3 cursor-pointer">
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
                <div class="mt-4">
                  <.button variant="primary" phx-disable-with="Enregistrement...">
                    Enregistrer mes rôles
                  </.button>
                </div>
              </form>
              <div class="mt-6 pt-4 border-t border-slate-200">
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
                  Quitter cet équipage
                </button>
              </div>
            </div>
          </div>

          <%!-- Raft info --%>
          <div class="bg-white rounded-xl shadow-sm border border-slate-200">
            <div class="p-6">
              <h3 class="text-lg font-semibold text-slate-900">Informations</h3>

              <%= if @raft.description do %>
                <div class="mt-2">
                  <p class="text-sm font-medium text-slate-400">Description</p>
                  <p class="whitespace-pre-wrap">{@raft.description}</p>
                </div>
              <% end %>

              <%= if @raft.forum_url do %>
                <div class="mt-4">
                  <p class="text-sm font-medium text-slate-400">Lien forum</p>
                  <a href={@raft.forum_url} target="_blank" class="text-indigo-600 hover:underline">
                    {@raft.forum_url}
                  </a>
                </div>
              <% end %>

              <div class="mt-4">
                <p class="text-sm font-medium text-slate-400">Statut</p>
                <%= if @raft.validated do %>
                  <span class="bg-green-100 text-green-700 text-xs font-medium px-2.5 py-0.5 rounded-full inline-flex items-center">
                    Radeau validé
                  </span>
                <% else %>
                  <span class="bg-slate-100 text-slate-600 text-xs font-medium px-2.5 py-0.5 rounded-full">
                    En attente de validation admin
                  </span>
                <% end %>
              </div>
            </div>
          </div>

          <%!-- Drums section --%>
          <div class="bg-white rounded-xl shadow-sm border border-slate-200" id="drums-section">
            <div class="p-6">
              <h3 class="text-lg font-semibold text-slate-900">Bidons</h3>

              <%!-- Summary --%>
              <%= if @drums_summary.requests != [] do %>
                <div class="space-y-2 mt-2">
                  <%= for req <- @drums_summary.requests do %>
                    <div class="flex items-center justify-between text-sm">
                      <span>
                        {req.quantity} bidons — {req.total_amount} €
                        ({req.unit_price} €/bidon)
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
                  <div class="text-sm font-medium pt-2 border-t border-slate-200">
                    Total payé : {@drums_summary.total_paid_quantity} bidons — {@drums_summary.total_paid_amount} €
                  </div>
                </div>
              <% end %>

              <%!-- Request form --%>
              <div class="mt-4">
                <h4 class="text-sm font-medium mb-2">
                  {if @pending_drum_request, do: "Modifier la demande", else: "Nouvelle demande"}
                </h4>
                <.form
                  for={@drum_form}
                  id="drum-request-form"
                  phx-change="validate_drums"
                  phx-submit="submit_drums"
                >
                  <div class="flex items-end gap-4">
                    <div class="flex-1">
                      <.input
                        field={@drum_form[:quantity]}
                        type="number"
                        label="Nombre de bidons"
                        min="0"
                      />
                    </div>
                    <.button variant="primary" phx-disable-with="Envoi...">
                      {if @pending_drum_request, do: "Modifier", else: "Demander"}
                    </.button>
                  </div>
                  <.input field={@drum_form[:note]} type="text" label="Note (optionnel)" />
                  <p class="text-xs text-slate-400 mt-2">
                    Tarif : {@drum_settings.unit_price} € / bidon
                    <%= if @drum_settings.rib_iban do %>
                      — IBAN : {@drum_settings.rib_iban}
                    <% end %>
                  </p>
                </.form>
              </div>
            </div>
          </div>

          <%!-- CUF section --%>
          <div class="bg-white rounded-xl shadow-sm border border-slate-200" id="cuf-section">
            <div class="p-6">
              <h3 class="text-lg font-semibold text-slate-900">CUF (Cotisation Urbaine Flottante)</h3>

              <div class="space-y-2 mt-2 text-sm">
                <p>
                  Participants validés :
                  <span class="font-medium">{@cuf_summary.total_validated_participants}</span>
                </p>
                <p>
                  Montant total validé :
                  <span class="font-medium">{@cuf_summary.total_validated_amount} €</span>
                </p>

                <%= if @cuf_summary.pending do %>
                  <div class="bg-amber-50 border border-amber-200 text-amber-800 rounded-xl p-4 flex items-start gap-3 text-sm mt-2">
                    <.icon name="hero-clock-mini" class="size-4" />
                    <span>
                      Déclaration en attente : {@cuf_summary.pending.participant_count} participants
                      ({@cuf_summary.pending.total_amount} €)
                    </span>
                  </div>
                <% end %>
              </div>

              <%!-- Captain can declare participants --%>
              <%= if @is_captain do %>
                <div class="mt-4">
                  <h4 class="text-sm font-medium mb-2">Déclarer les participants</h4>
                  <form phx-submit="submit_cuf" id="cuf-declaration-form">
                    <div class="space-y-1">
                      <%= for member <- @raft.crew.crew_members do %>
                        <label class="flex items-center gap-3 cursor-pointer">
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
                    <div class="mt-4">
                      <.button variant="primary" phx-disable-with="Envoi...">
                        Soumettre la déclaration
                      </.button>
                    </div>
                  </form>
                </div>
              <% end %>
            </div>
          </div>

          <%!-- Quick links --%>
          <div class="bg-white rounded-xl shadow-sm border border-slate-200">
            <div class="p-6">
              <h3 class="text-lg font-semibold text-slate-900">Actions</h3>
              <div class="flex flex-wrap gap-2 mt-2">
                <.link
                  navigate={~p"/fiche-inscription"}
                  class="bg-indigo-600 text-white rounded-lg px-3 py-1.5 text-sm font-medium hover:bg-indigo-700 transition inline-flex items-center"
                >
                  Ma fiche d'inscription
                </.link>
                <%= if @raft.forum_url do %>
                  <a
                    href={@raft.forum_url}
                    target="_blank"
                    class="text-sm text-slate-600 hover:bg-slate-50 rounded-lg px-3 py-1.5 font-medium transition"
                  >
                    Discussion forum
                  </a>
                <% end %>
              </div>
            </div>
          </div>
        </div>

        <%!-- Crew members sidebar --%>
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
                    <%= if @is_manager && member.user_id != @current_scope.user.id do %>
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
