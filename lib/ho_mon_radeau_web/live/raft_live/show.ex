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
    <.header>
      {@raft.name}
      <:subtitle>
        <%= if @raft.validated do %>
          <span class="bg-green-100 text-green-700 text-xs font-medium px-2.5 py-0.5 rounded-full inline-flex items-center">
            Radeau validé
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
          class="text-sm text-slate-600 hover:bg-slate-50 rounded-lg px-3 py-1.5 font-medium transition"
        >
          ← Retour à la liste
        </.link>
      </:actions>
    </.header>

    <div class="mt-8 grid gap-8 lg:grid-cols-3">
      <div class="lg:col-span-2 space-y-6">
        <%= if @raft.description do %>
          <div class="prose max-w-none">
            <h3>Description</h3>
            <p class="whitespace-pre-wrap">{@raft.description}</p>
          </div>
        <% end %>

        <%= if @raft.forum_url do %>
          <div>
            <h3 class="font-semibold mb-2">Lien forum</h3>
            <a href={@raft.forum_url} target="_blank" class="text-indigo-600 hover:underline">
              {@raft.forum_url}
            </a>
          </div>
        <% end %>
      </div>

      <div class="space-y-6">
        <div class="bg-white rounded-xl shadow-sm border border-slate-200">
          <div class="p-6">
            <h3 class="text-lg font-semibold text-slate-900">Équipage</h3>
            <p class="text-3xl font-bold">
              {length(@raft.crew.crew_members)}
              <span class="text-base font-normal text-slate-400">
                membre{if length(@raft.crew.crew_members) > 1, do: "s"}
              </span>
            </p>

            <div class="border-t border-slate-100 my-4"></div>

            <ul class="space-y-2">
              <%= for member <- @raft.crew.crew_members do %>
                <li class="flex items-center gap-2">
                  <span class="font-medium">{Accounts.display_name(member.user)}</span>
                  <%= if member.is_captain do %>
                    <span class="bg-indigo-100 text-indigo-700 text-xs font-medium px-2 py-0.5 rounded-full">
                      Capitaine
                    </span>
                  <% end %>
                  <%= if member.is_manager do %>
                    <span class="bg-indigo-100 text-indigo-600 text-xs font-medium px-2 py-0.5 rounded-full">
                      Gestionnaire
                    </span>
                  <% end %>
                </li>
              <% end %>
            </ul>
          </div>
        </div>

        <%= if @current_scope do %>
          <div class="bg-white rounded-xl shadow-sm border border-slate-200">
            <div class="p-6">
              <%= cond do %>
                <% @is_member -> %>
                  <p class="text-green-600 font-medium">
                    ✓ Vous êtes membre de cet équipage
                  </p>
                  <.link
                    navigate={~p"/mon-radeau"}
                    class="bg-indigo-600 text-white rounded-lg px-3 py-1.5 text-sm font-medium hover:bg-indigo-700 transition inline-flex items-center mt-2"
                  >
                    Voir la page équipage
                  </.link>
                <% @user_crew != nil -> %>
                  <p class="text-slate-400">
                    Vous êtes déjà membre d'un autre équipage.
                  </p>
                <% @has_pending_request -> %>
                  <p class="text-indigo-500">
                    ⏳ Votre demande est en attente de validation.
                  </p>
                <% !@current_scope.user.validated -> %>
                  <p class="text-amber-600 text-sm">
                    Votre compte doit être validé par l'équipe d'accueil avant de pouvoir rejoindre un équipage.
                  </p>
                <% true -> %>
                  <h3 class="text-lg font-semibold text-slate-900 text-base">
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
                      class="bg-indigo-600 text-white rounded-lg px-5 py-2.5 font-medium hover:bg-indigo-700 transition inline-flex items-center w-full"
                    >
                      Demander à rejoindre
                    </button>
                  </form>
              <% end %>
            </div>
          </div>
        <% else %>
          <div class="bg-white rounded-xl shadow-sm border border-slate-200">
            <div class="p-6">
              <p class="text-slate-400">
                <.link navigate={~p"/users/log-in"} class="text-indigo-600 hover:underline">
                  Connectez-vous
                </.link>
                pour rejoindre cet équipage.
              </p>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
