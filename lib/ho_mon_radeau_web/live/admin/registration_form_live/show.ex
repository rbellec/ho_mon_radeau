defmodule HoMonRadeauWeb.Admin.RegistrationFormLive.Show do
  @moduledoc """
  Admin LiveView for viewing and reviewing a single registration form.
  """
  use HoMonRadeauWeb, :live_view

  alias HoMonRadeau.Events
  alias HoMonRadeau.Events.RegistrationFormNotifier

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    form = Events.get_registration_form!(id)

    socket =
      socket
      |> assign(:form, form)
      |> assign(:page_title, "Fiche de #{form.user.nickname || form.user.email}")
      |> assign(:rejection_reason, "")
      |> assign(:show_reject_modal, false)
      |> load_file_url()

    {:ok, socket}
  end

  defp load_file_url(socket) do
    case Events.get_registration_form_url(socket.assigns.form) do
      {:ok, url} -> assign(socket, :file_url, url)
      {:error, _} -> assign(socket, :file_url, nil)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto">
      <.header>
        <.link navigate={~p"/admin/fiches"} class="text-base-content/70 hover:text-base-content">
          <.icon name="hero-arrow-left" class="size-5" />
        </.link>
        Fiche d'inscription
        <:subtitle>
          <%= @form.user.nickname || @form.user.email %>
        </:subtitle>
        <:actions>
          <.status_badge status={@form.status} />
        </:actions>
      </.header>

      <div class="mt-6 grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div class="space-y-6">
          <.info_card form={@form} />
          <.action_card
            form={@form}
            show_reject_modal={@show_reject_modal}
            rejection_reason={@rejection_reason}
          />
          <.history_card user={@form.user} edition={@form.edition} />
        </div>

        <div>
          <.file_preview file_url={@file_url} form={@form} />
        </div>
      </div>
    </div>
    """
  end

  defp info_card(assigns) do
    ~H"""
    <div class="card bg-base-200">
      <div class="card-body">
        <h2 class="card-title">
          <.icon name="hero-user" class="size-5" />
          Informations
        </h2>

        <dl class="space-y-2 mt-4">
          <div class="flex justify-between">
            <dt class="text-base-content/70">Participant</dt>
            <dd class="font-medium"><%= @form.user.nickname || "Sans pseudo" %></dd>
          </div>
          <div class="flex justify-between">
            <dt class="text-base-content/70">Email</dt>
            <dd><%= @form.user.email %></dd>
          </div>
          <div class="flex justify-between">
            <dt class="text-base-content/70">Type de fiche</dt>
            <dd>
              <span class={[
                "badge",
                @form.form_type == "captain" && "badge-warning",
                @form.form_type == "participant" && "badge-info"
              ]}>
                <%= if @form.form_type == "captain", do: "Capitaine", else: "Participant" %>
              </span>
            </dd>
          </div>
          <div class="flex justify-between">
            <dt class="text-base-content/70">Fichier</dt>
            <dd><%= @form.file_name %></dd>
          </div>
          <div class="flex justify-between">
            <dt class="text-base-content/70">Taille</dt>
            <dd><%= format_file_size(@form.file_size) %></dd>
          </div>
          <div class="flex justify-between">
            <dt class="text-base-content/70">Envoyée le</dt>
            <dd><%= Calendar.strftime(@form.uploaded_at, "%d/%m/%Y à %H:%M") %></dd>
          </div>
          <%= if @form.reviewed_at do %>
            <div class="flex justify-between">
              <dt class="text-base-content/70">Revue le</dt>
              <dd><%= Calendar.strftime(@form.reviewed_at, "%d/%m/%Y à %H:%M") %></dd>
            </div>
            <%= if @form.reviewed_by do %>
              <div class="flex justify-between">
                <dt class="text-base-content/70">Par</dt>
                <dd><%= @form.reviewed_by.nickname || @form.reviewed_by.email %></dd>
              </div>
            <% end %>
          <% end %>
        </dl>

        <%= if @form.status == "rejected" && @form.rejection_reason do %>
          <div class="alert alert-error mt-4">
            <.icon name="hero-exclamation-circle" class="size-5" />
            <div>
              <strong>Motif du rejet :</strong>
              <p><%= @form.rejection_reason %></p>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp action_card(assigns) do
    ~H"""
    <div class="card bg-base-200">
      <div class="card-body">
        <h2 class="card-title">
          <.icon name="hero-cog-6-tooth" class="size-5" />
          Actions
        </h2>

        <%= if @form.status == "pending" do %>
          <div class="flex gap-2 mt-4">
            <button phx-click="approve" class="btn btn-success flex-1">
              <.icon name="hero-check" class="size-5" />
              Valider
            </button>
            <button phx-click="show-reject-modal" class="btn btn-error flex-1">
              <.icon name="hero-x-mark" class="size-5" />
              Rejeter
            </button>
          </div>
        <% else %>
          <p class="text-base-content/70 mt-4">
            Cette fiche a déjà été traitée.
          </p>
        <% end %>

        <%= if @show_reject_modal do %>
          <div class="mt-4 p-4 bg-base-300 rounded-lg">
            <h3 class="font-semibold mb-2">Motif du rejet</h3>
            <form phx-submit="reject">
              <textarea
                name="reason"
                class="textarea textarea-bordered w-full"
                placeholder="Expliquez pourquoi cette fiche est rejetée..."
                rows="3"
                required
              ><%= @rejection_reason %></textarea>
              <div class="flex gap-2 mt-2">
                <button type="submit" class="btn btn-error btn-sm">Confirmer le rejet</button>
                <button type="button" phx-click="hide-reject-modal" class="btn btn-ghost btn-sm">
                  Annuler
                </button>
              </div>
            </form>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp history_card(assigns) do
    forms = Events.list_user_registration_forms(assigns.user.id, assigns.edition.id)
    assigns = assign(assigns, :forms, forms)

    ~H"""
    <div class="card bg-base-200">
      <div class="card-body">
        <h2 class="card-title">
          <.icon name="hero-clock" class="size-5" />
          Historique
        </h2>

        <%= if length(@forms) > 1 do %>
          <ul class="timeline timeline-vertical mt-4">
            <%= for {form, idx} <- Enum.with_index(@forms) do %>
              <li>
                <%= if idx > 0 do %>
                  <hr />
                <% end %>
                <div class="timeline-start text-xs text-base-content/70">
                  <%= Calendar.strftime(form.uploaded_at, "%d/%m") %>
                </div>
                <div class="timeline-middle">
                  <.status_icon status={form.status} />
                </div>
                <div class="timeline-end timeline-box">
                  <%= form.file_name %>
                </div>
                <%= if idx < length(@forms) - 1 do %>
                  <hr />
                <% end %>
              </li>
            <% end %>
          </ul>
        <% else %>
          <p class="text-base-content/70 mt-2">Première soumission</p>
        <% end %>
      </div>
    </div>
    """
  end

  defp file_preview(assigns) do
    ~H"""
    <div class="card bg-base-200 h-full">
      <div class="card-body">
        <h2 class="card-title">
          <.icon name="hero-document" class="size-5" />
          Aperçu
        </h2>

        <%= if @file_url do %>
          <%= if is_image?(@form.content_type) do %>
            <div class="mt-4">
              <img src={@file_url} alt="Fiche d'inscription" class="max-w-full rounded-lg" />
            </div>
          <% else %>
            <div class="mt-4">
              <iframe src={@file_url} class="w-full h-[600px] rounded-lg border border-base-300">
              </iframe>
            </div>
          <% end %>
          <a href={@file_url} target="_blank" class="btn btn-ghost btn-sm mt-4">
            <.icon name="hero-arrow-top-right-on-square" class="size-4" />
            Ouvrir dans un nouvel onglet
          </a>
        <% else %>
          <div class="alert alert-warning mt-4">
            <.icon name="hero-exclamation-triangle" class="size-5" />
            <span>Impossible de charger l'aperçu du fichier</span>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp status_badge(assigns) do
    ~H"""
    <span class={[
      "badge badge-lg",
      @status == "pending" && "badge-info",
      @status == "approved" && "badge-success",
      @status == "rejected" && "badge-error"
    ]}>
      <%= case @status do
        "pending" -> "En attente"
        "approved" -> "Validée"
        "rejected" -> "Rejetée"
      end %>
    </span>
    """
  end

  defp status_icon(assigns) do
    ~H"""
    <span class={[
      "size-4 rounded-full",
      @status == "pending" && "bg-info",
      @status == "approved" && "bg-success",
      @status == "rejected" && "bg-error"
    ]}>
    </span>
    """
  end

  @impl true
  def handle_event("approve", _params, socket) do
    admin = socket.assigns.current_scope.user
    form = socket.assigns.form

    case Events.approve_registration_form(form, admin) do
      {:ok, updated_form} ->
        # Send approval notification to user
        RegistrationFormNotifier.deliver_form_approved(form.user)

        {:noreply,
         socket
         |> assign(:form, Events.get_registration_form!(updated_form.id))
         |> put_flash(:info, "Fiche validée - notification envoyée")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de la validation")}
    end
  end

  @impl true
  def handle_event("show-reject-modal", _params, socket) do
    {:noreply, assign(socket, :show_reject_modal, true)}
  end

  @impl true
  def handle_event("hide-reject-modal", _params, socket) do
    {:noreply, assign(socket, :show_reject_modal, false)}
  end

  @impl true
  def handle_event("reject", %{"reason" => reason}, socket) do
    admin = socket.assigns.current_scope.user
    form = socket.assigns.form

    case Events.reject_registration_form(form, admin, reason) do
      {:ok, updated_form} ->
        # Send rejection email to user
        RegistrationFormNotifier.deliver_form_rejected(form.user, updated_form)

        # Send notification to crew managers
        crew = Events.get_user_crew(form.user)

        if crew do
          managers = Events.get_crew_managers(crew.id)
          raft = Events.get_raft!(crew.raft_id)

          RegistrationFormNotifier.deliver_form_rejected_to_managers(
            managers,
            form.user,
            updated_form,
            raft.name
          )
        end

        {:noreply,
         socket
         |> assign(:form, Events.get_registration_form!(updated_form.id))
         |> assign(:show_reject_modal, false)
         |> put_flash(:info, "Fiche rejetée - notifications envoyées")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors du rejet")}
    end
  end

  # Helper functions

  defp format_file_size(nil), do: "?"
  defp format_file_size(bytes) when bytes < 1024, do: "#{bytes} o"
  defp format_file_size(bytes) when bytes < 1_048_576, do: "#{Float.round(bytes / 1024, 1)} Ko"
  defp format_file_size(bytes), do: "#{Float.round(bytes / 1_048_576, 1)} Mo"

  defp is_image?(content_type) when is_binary(content_type) do
    String.starts_with?(content_type, "image/")
  end

  defp is_image?(_), do: false
end
