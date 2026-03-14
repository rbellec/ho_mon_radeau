defmodule HoMonRadeauWeb.RaftLive.Show do
  use HoMonRadeauWeb, :live_view

  alias HoMonRadeau.Events
  alias HoMonRadeau.Accounts

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    edition = Events.get_current_edition()

    case edition && Events.get_raft_by_slug(slug, edition.id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Radeau introuvable.")
         |> redirect(to: ~p"/radeaux")}

      raft ->
        raft = Events.preload_raft_details(raft)

        {:ok,
         socket
         |> assign(:page_title, raft.name)
         |> assign(:raft, raft)
         |> assign(:edition, edition)
         |> assign_user_context()}
    end
  end

  defp assign_user_context(socket) do
    # current_scope is set by on_mount hook in router
    case socket.assigns.current_scope do
      %{user: user} ->
        user_crew = Events.get_user_crew(user)
        is_member = user_crew && user_crew.id == socket.assigns.raft.crew.id
        is_manager = is_member && Events.is_crew_manager?(socket.assigns.raft.crew, user)
        has_pending_request = Events.has_pending_join_request?(user, socket.assigns.raft.crew)

        socket
        |> assign(:user_crew, user_crew)
        |> assign(:is_member, is_member)
        |> assign(:is_manager, is_manager)
        |> assign(:has_pending_request, has_pending_request)

      _ ->
        socket
        |> assign(:user_crew, nil)
        |> assign(:is_member, false)
        |> assign(:is_manager, false)
        |> assign(:has_pending_request, false)
    end
  end

  @impl true
  def handle_event("request_join", %{"message" => message}, socket) do
    user = socket.assigns.current_scope.user
    crew = socket.assigns.raft.crew

    case Events.create_join_request(crew, user, message) do
      {:ok, _request} ->
        {:noreply,
         socket
         |> put_flash(:info, "Votre demande a été envoyée aux gestionnaires.")
         |> assign(:has_pending_request, true)}

      {:error, :already_in_crew} ->
        {:noreply, put_flash(socket, :error, "Vous êtes déjà membre d'un équipage.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de l'envoi de la demande.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@raft.name}
        <:subtitle>
          <%= if @raft.validated do %>
            <span class="bg-green-100 text-green-700 text-xs font-medium px-2.5 py-0.5 rounded-full inline-flex items-center gap-1">
              <.icon name="hero-check-circle-mini" class="size-3.5" /> Radeau validé
            </span>
          <% else %>
            <span class="bg-slate-100 text-slate-600 text-xs font-medium px-2.5 py-0.5 rounded-full">
              Radeau proposé
            </span>
          <% end %>
        </:subtitle>
        <:actions>
          <.link
            navigate={~p"/radeaux"}
            class="text-sm text-slate-500 hover:text-indigo-600 hover:bg-slate-50 rounded-lg px-3 py-1.5 font-medium transition inline-flex items-center gap-1"
          >
            <.icon name="hero-arrow-left-mini" class="size-4" /> Retour à la liste
          </.link>
        </:actions>
      </.header>

      <div class="mt-8 grid gap-8 lg:grid-cols-3">
        <%!-- Main content --%>
        <div class="lg:col-span-2 space-y-6">
          <%= if @raft.description do %>
            <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
              <h3 class="text-base font-semibold text-slate-900 mb-3">Description</h3>
              <p class="whitespace-pre-wrap text-slate-600 leading-relaxed">{@raft.description}</p>
            </div>
          <% end %>

          <%= if @raft.forum_url do %>
            <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
              <h3 class="text-base font-semibold text-slate-900 mb-2">Lien forum</h3>
              <a
                href={@raft.forum_url}
                target="_blank"
                class="text-indigo-600 hover:underline inline-flex items-center gap-1 text-sm"
              >
                <.icon name="hero-arrow-top-right-on-square-mini" class="size-4" />
                {@raft.forum_url}
              </a>
            </div>
          <% end %>
        </div>

        <%!-- Sidebar --%>
        <div class="space-y-6">
          <%!-- Crew members card --%>
          <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
            <h3 class="text-base font-semibold text-slate-900 mb-3">Équipage</h3>
            <p class="text-3xl font-bold text-slate-900">
              {length(@raft.crew.crew_members)}
              <span class="text-base font-normal text-slate-400">
                membre{if length(@raft.crew.crew_members) > 1, do: "s"}
              </span>
            </p>

            <div class="border-t border-slate-100 my-4"></div>

            <ul class="space-y-3">
              <%= for member <- @raft.crew.crew_members do %>
                <li class="flex items-center gap-2 flex-wrap">
                  <span class="font-medium text-slate-800">{Accounts.display_name(member.user)}</span>
                  <%= if member.is_captain do %>
                    <span class="bg-indigo-100 text-indigo-700 text-xs font-medium px-2 py-0.5 rounded-full">
                      Capitaine
                    </span>
                  <% end %>
                  <%= if member.is_manager do %>
                    <span class="bg-slate-100 text-slate-600 text-xs font-medium px-2 py-0.5 rounded-full">
                      Gestionnaire
                    </span>
                  <% end %>
                </li>
              <% end %>
            </ul>
          </div>

          <%!-- Action card --%>
          <%= if @current_scope do %>
            <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
              <%= cond do %>
                <% @is_member -> %>
                  <div class="flex items-center gap-2 text-green-600 font-medium mb-3">
                    <.icon name="hero-check-circle" class="size-5" />
                    <span>Vous êtes membre de cet équipage</span>
                  </div>
                  <.link
                    navigate={~p"/mon-radeau"}
                    class="bg-indigo-600 text-white rounded-lg px-4 py-2 text-sm font-medium hover:bg-indigo-700 transition inline-flex items-center justify-center w-full"
                  >
                    Voir la page équipage
                  </.link>
                <% @user_crew != nil -> %>
                  <p class="text-slate-500 text-sm">
                    Vous êtes déjà membre d'un autre équipage.
                  </p>
                <% @has_pending_request -> %>
                  <div class="bg-indigo-50 border border-indigo-200 text-indigo-800 rounded-xl p-4 text-sm flex items-center gap-2">
                    <.icon name="hero-clock" class="size-5 shrink-0" />
                    <span>Votre demande est en attente de validation.</span>
                  </div>
                <% !@current_scope.user.validated -> %>
                  <div class="bg-amber-50 border border-amber-200 text-amber-800 rounded-xl p-4 text-sm flex items-start gap-2">
                    <.icon name="hero-exclamation-triangle" class="size-5 shrink-0 mt-0.5" />
                    <span>
                      Votre compte doit être validé par l'équipe d'accueil avant de pouvoir rejoindre un équipage.
                    </span>
                  </div>
                <% true -> %>
                  <h3 class="text-base font-semibold text-slate-900 mb-3">
                    Rejoindre cet équipage
                  </h3>
                  <form phx-submit="request_join" class="space-y-3">
                    <textarea
                      name="message"
                      class="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
                      placeholder="Message de motivation (optionnel)"
                      rows="3"
                    ></textarea>
                    <button
                      type="submit"
                      class="bg-indigo-600 text-white rounded-lg px-5 py-2.5 font-medium hover:bg-indigo-700 transition inline-flex items-center justify-center w-full"
                    >
                      Demander à rejoindre
                    </button>
                  </form>
              <% end %>
            </div>
          <% else %>
            <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
              <p class="text-slate-500 text-sm">
                <.link
                  navigate={~p"/users/log-in"}
                  class="text-indigo-600 hover:underline font-medium"
                >
                  Connectez-vous
                </.link>
                pour rejoindre cet équipage.
              </p>
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
