defmodule HoMonRadeau.Events.RegistrationFormNotifier do
  @moduledoc """
  Notifier for registration form related emails.
  """
  import Swoosh.Email

  alias HoMonRadeau.Mailer

  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Tutto Blu", "contact@example.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  defp deliver_to_many(recipients, subject, body) do
    Enum.each(recipients, fn recipient ->
      deliver(recipient, subject, body)
    end)

    :ok
  end

  @doc """
  Notify a user that their registration form was rejected.
  """
  def deliver_form_rejected(user, form) do
    deliver(user.email, "[Tutto Blu] Fiche d'inscription rejetée", """

    ==============================

    Bonjour #{user.nickname || user.email},

    Votre fiche d'inscription a été examinée et ne peut pas être validée en l'état.

    Motif : #{form.rejection_reason}

    Merci de soumettre une nouvelle fiche corrigée.

    Vous pouvez accéder à la page d'upload de votre fiche ici :
    [URL à ajouter]

    L'équipe Tutto Blu

    ==============================
    """)
  end

  @doc """
  Notify crew managers that a crew member's form was rejected.
  """
  def deliver_form_rejected_to_managers(managers, user, form, raft_name) do
    manager_emails = Enum.map(managers, & &1.user.email)

    deliver_to_many(manager_emails, "[Tutto Blu] Fiche rejetée - #{raft_name}", """

    ==============================

    Bonjour,

    La fiche d'inscription de #{user.nickname || user.email} (équipage #{raft_name}) a été rejetée.

    Motif : #{form.rejection_reason}

    Une nouvelle fiche doit être soumise. Merci de vous assurer que votre équipier·ère corrige sa fiche.

    L'équipe Tutto Blu

    ==============================
    """)
  end

  @doc """
  Send a reminder to users who haven't submitted their registration form.
  """
  def deliver_form_reminder(user, edition, raft_name) do
    deadline_text =
      if edition.registration_deadline do
        "avant le #{Calendar.strftime(edition.registration_deadline, "%d/%m/%Y")}"
      else
        "dès que possible"
      end

    deliver(user.email, "[Tutto Blu] Rappel - Fiche d'inscription", """

    ==============================

    Bonjour #{user.nickname || user.email},

    Nous n'avons pas encore reçu votre fiche d'inscription pour Tutto Blu #{edition.year}.

    En tant que membre de l'équipage "#{raft_name}", vous devez soumettre votre fiche #{deadline_text}.

    Vous pouvez accéder à la page d'upload de votre fiche ici :
    [URL à ajouter]

    Si vous avez des questions, n'hésitez pas à nous contacter sur le forum.

    L'équipe Tutto Blu

    ==============================
    """)
  end

  @doc """
  Notify a user that their registration form was approved.
  """
  def deliver_form_approved(user) do
    deliver(user.email, "[Tutto Blu] Fiche d'inscription validée", """

    ==============================

    Bonjour #{user.nickname || user.email},

    Bonne nouvelle ! Votre fiche d'inscription a été validée.

    Vous êtes maintenant inscrit·e pour Tutto Blu. Préparez-vous à construire votre radeau !

    L'équipe Tutto Blu

    ==============================
    """)
  end
end
