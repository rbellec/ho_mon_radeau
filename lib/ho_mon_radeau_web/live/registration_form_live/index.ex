defmodule HoMonRadeauWeb.RegistrationFormLive.Index do
  @moduledoc """
  LiveView for users to upload their registration form.
  """
  use HoMonRadeauWeb, :live_view

  alias HoMonRadeau.Events

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    edition = Events.get_current_edition()

    if edition do
      form_type = Events.required_form_type(user, edition.id)
      current_form = Events.get_current_registration_form(user.id, edition.id)
      form_status = Events.registration_form_status(user, edition.id)

      socket =
        socket
        |> assign(:edition, edition)
        |> assign(:form_type, form_type)
        |> assign(:current_form, current_form)
        |> assign(:form_status, form_status)
        |> assign(:page_title, "Fiche d'inscription")
        |> allow_upload(:form_file,
          accept: ~w(.pdf .jpg .jpeg .png .gif .webp),
          max_entries: 1,
          max_file_size: 10_000_000
        )

      {:ok, socket}
    else
      {:ok,
       socket
       |> put_flash(:error, "Aucune édition en cours")
       |> redirect(to: ~p"/")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto">
      <.header>
        Fiche d'inscription
        <:subtitle>
          <%= if @form_type do %>
            Fiche <%= if @form_type == :captain, do: "capitaine", else: "participant" %>
          <% else %>
            Vous devez d'abord rejoindre un équipage
          <% end %>
        </:subtitle>
      </.header>

      <%= if @form_type do %>
        <div class="mt-6 space-y-6">
          <.form_instructions edition={@edition} form_type={@form_type} />
          <.current_status form={@current_form} status={@form_status} />
          <.upload_form uploads={@uploads} />
        </div>
      <% else %>
        <div class="alert alert-warning mt-6">
          <.icon name="hero-exclamation-triangle" class="size-6" />
          <span>Vous devez d'abord rejoindre un équipage avant de pouvoir soumettre votre fiche d'inscription.</span>
        </div>
      <% end %>
    </div>
    """
  end

  defp form_instructions(assigns) do
    ~H"""
    <div class="card bg-base-200">
      <div class="card-body">
        <h2 class="card-title">
          <.icon name="hero-document-text" class="size-6" />
          Instructions
        </h2>

        <p class="text-base-content/80">
          Pour participer à Tutto Blu, vous devez remplir et signer votre fiche d'inscription.
        </p>

        <%= if @edition.registration_deadline do %>
          <div class="alert alert-info mt-4">
            <.icon name="hero-calendar" class="size-5" />
            <span>
              <strong>Date limite :</strong>
              <%= Calendar.strftime(@edition.registration_deadline, "%d/%m/%Y") %>
            </span>
          </div>
        <% end %>

        <div class="mt-4">
          <h3 class="font-semibold mb-2">Étapes :</h3>
          <ol class="list-decimal list-inside space-y-2 text-base-content/80">
            <li>
              Téléchargez le document :
              <%= if @form_type == :captain && @edition.captain_form_url do %>
                <a href={@edition.captain_form_url} target="_blank" class="link link-primary">
                  Fiche capitaine
                </a>
              <% else %>
                <%= if @edition.participant_form_url do %>
                  <a href={@edition.participant_form_url} target="_blank" class="link link-primary">
                    Fiche participant
                  </a>
                <% else %>
                  <span class="text-warning">(lien à venir)</span>
                <% end %>
              <% end %>
            </li>
            <li>Remplissez-le et signez-le</li>
            <li>Scannez-le ou prenez une photo lisible</li>
            <li>Uploadez-le ci-dessous</li>
          </ol>
        </div>
      </div>
    </div>
    """
  end

  defp current_status(assigns) do
    ~H"""
    <div class="card bg-base-200">
      <div class="card-body">
        <h2 class="card-title">
          <.icon name="hero-clipboard-document-check" class="size-6" />
          Statut actuel
        </h2>

        <div class={[
          "alert mt-2",
          status_alert_class(@status)
        ]}>
          <.icon name={status_icon(@status)} class="size-5" />
          <span><%= status_text(@status) %></span>
        </div>

        <%= if @form && @status == :rejected && @form.rejection_reason do %>
          <div class="alert alert-error mt-2">
            <.icon name="hero-exclamation-circle" class="size-5" />
            <div>
              <strong>Motif du rejet :</strong>
              <p><%= @form.rejection_reason %></p>
            </div>
          </div>
        <% end %>

        <%= if @form do %>
          <div class="mt-4 text-sm text-base-content/70">
            <p>
              <strong>Dernier envoi :</strong>
              <%= Calendar.strftime(@form.uploaded_at, "%d/%m/%Y à %H:%M") %>
            </p>
            <p>
              <strong>Fichier :</strong>
              <%= @form.file_name %>
            </p>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp upload_form(assigns) do
    ~H"""
    <div class="card bg-base-200">
      <div class="card-body">
        <h2 class="card-title">
          <.icon name="hero-arrow-up-tray" class="size-6" />
          Envoyer votre fiche
        </h2>

        <form phx-submit="save" phx-change="validate" class="mt-4">
          <div
            class="border-2 border-dashed border-base-300 rounded-lg p-8 text-center hover:border-primary transition-colors"
            phx-drop-target={@uploads.form_file.ref}
          >
            <.live_file_input upload={@uploads.form_file} class="hidden" />

            <%= for entry <- @uploads.form_file.entries do %>
              <div class="flex items-center justify-between bg-base-100 p-3 rounded-lg mb-4">
                <div class="flex items-center gap-3">
                  <.icon name="hero-document" class="size-8 text-primary" />
                  <div class="text-left">
                    <p class="font-medium"><%= entry.client_name %></p>
                    <p class="text-sm text-base-content/70">
                      <%= format_file_size(entry.client_size) %>
                    </p>
                  </div>
                </div>
                <button
                  type="button"
                  phx-click="cancel-upload"
                  phx-value-ref={entry.ref}
                  class="btn btn-ghost btn-sm btn-circle"
                >
                  <.icon name="hero-x-mark" class="size-5" />
                </button>
              </div>

              <div class="w-full bg-base-300 rounded-full h-2 mb-4">
                <div class="bg-primary h-2 rounded-full" style={"width: #{entry.progress}%"}></div>
              </div>

              <%= for err <- upload_errors(@uploads.form_file, entry) do %>
                <p class="text-error text-sm"><%= error_to_string(err) %></p>
              <% end %>
            <% end %>

            <%= if @uploads.form_file.entries == [] do %>
              <.icon name="hero-cloud-arrow-up" class="size-12 mx-auto text-base-content/50" />
              <p class="mt-2 text-base-content/70">
                Glissez-déposez votre fichier ici ou
                <label for={@uploads.form_file.ref} class="link link-primary cursor-pointer">
                  parcourez
                </label>
              </p>
              <p class="text-sm text-base-content/50 mt-1">
                PDF ou image (max 10 Mo)
              </p>
            <% end %>
          </div>

          <%= for err <- upload_errors(@uploads.form_file) do %>
            <p class="text-error text-sm mt-2"><%= error_to_string(err) %></p>
          <% end %>

          <div class="mt-4">
            <button
              type="submit"
              class="btn btn-primary w-full"
              disabled={@uploads.form_file.entries == []}
            >
              <.icon name="hero-arrow-up-tray" class="size-5" />
              Envoyer ma fiche
            </button>
          </div>
        </form>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :form_file, ref)}
  end

  @impl true
  def handle_event("save", _params, socket) do
    user = socket.assigns.current_scope.user
    edition = socket.assigns.edition

    uploaded_files =
      consume_uploaded_entries(socket, :form_file, fn %{path: path}, entry ->
        content = File.read!(path)

        {:ok,
         %{
           filename: entry.client_name,
           content: content,
           content_type: entry.client_type
         }}
      end)

    case uploaded_files do
      [file_params] ->
        case Events.upload_registration_form(user, edition.id, file_params) do
          {:ok, form} ->
            {:noreply,
             socket
             |> assign(:current_form, form)
             |> assign(:form_status, :pending)
             |> put_flash(:info, "Fiche envoyée avec succès ! Elle sera examinée prochainement.")}

          {:error, :not_in_crew} ->
            {:noreply, put_flash(socket, :error, "Vous devez rejoindre un équipage")}

          {:error, changeset} ->
            {:noreply, put_flash(socket, :error, "Erreur lors de l'envoi: #{inspect(changeset.errors)}")}
        end

      [] ->
        {:noreply, put_flash(socket, :error, "Veuillez sélectionner un fichier")}
    end
  end

  # Helper functions

  defp status_alert_class(:missing), do: "alert-warning"
  defp status_alert_class(:pending), do: "alert-info"
  defp status_alert_class(:approved), do: "alert-success"
  defp status_alert_class(:rejected), do: "alert-error"

  defp status_icon(:missing), do: "hero-exclamation-triangle"
  defp status_icon(:pending), do: "hero-clock"
  defp status_icon(:approved), do: "hero-check-circle"
  defp status_icon(:rejected), do: "hero-x-circle"

  defp status_text(:missing), do: "Fiche non envoyée"
  defp status_text(:pending), do: "Fiche en attente de validation"
  defp status_text(:approved), do: "Fiche validée"
  defp status_text(:rejected), do: "Fiche rejetée - veuillez en soumettre une nouvelle"

  defp format_file_size(bytes) when bytes < 1024, do: "#{bytes} o"
  defp format_file_size(bytes) when bytes < 1_048_576, do: "#{Float.round(bytes / 1024, 1)} Ko"
  defp format_file_size(bytes), do: "#{Float.round(bytes / 1_048_576, 1)} Mo"

  defp error_to_string(:too_large), do: "Fichier trop volumineux (max 10 Mo)"
  defp error_to_string(:not_accepted), do: "Type de fichier non accepté (PDF ou image uniquement)"
  defp error_to_string(:too_many_files), do: "Un seul fichier autorisé"
  defp error_to_string(err), do: "Erreur: #{inspect(err)}"
end
