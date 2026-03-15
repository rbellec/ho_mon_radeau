defmodule HoMonRadeauWeb.UserSessionController do
  use HoMonRadeauWeb, :controller

  alias HoMonRadeau.Accounts
  alias HoMonRadeauWeb.UserAuth

  def new(conn, _params) do
    email = get_in(conn.assigns, [:current_scope, Access.key(:user), Access.key(:email)])
    form = Phoenix.Component.to_form(%{"email" => email}, as: "user")

    render(conn, :new, form: form)
  end

  # magic link login
  def create(conn, %{"user" => %{"token" => token} = user_params} = params) do
    info =
      case params do
        %{"_action" => "confirmed"} -> "Email confirmé avec succès. Bienvenue !"
        _ -> "Content de vous revoir !"
      end

    case Accounts.login_user_by_magic_link(token) do
      {:ok, {user, _expired_tokens}} ->
        conn
        |> put_flash(:info, info)
        |> UserAuth.log_in_user(user, user_params)

      # User has a password - confirm them but require password login
      {:ok, :confirmed_with_password, _user} ->
        conn
        |> put_flash(
          :info,
          "Email confirmé ! Vous pouvez maintenant vous connecter avec votre mot de passe."
        )
        |> redirect(to: ~p"/users/log-in")

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Ce lien est invalide ou a expiré.")
        |> render(:new, form: Phoenix.Component.to_form(%{}, as: "user"))
    end
  end

  # email + password login
  def create(conn, %{"user" => %{"email" => email, "password" => password} = user_params}) do
    user = Accounts.get_user_by_email_and_password(email, password)

    cond do
      user && is_nil(user.confirmed_at) ->
        # User exists but email not confirmed
        form = Phoenix.Component.to_form(user_params, as: "user")

        conn
        |> put_flash(
          :error,
          "Veuillez confirmer votre email avant de vous connecter. Vérifiez votre boîte de réception."
        )
        |> render(:new, form: form)

      user ->
        conn
        |> put_flash(:info, "Content de vous revoir !")
        |> UserAuth.log_in_user(user, user_params)

      true ->
        form = Phoenix.Component.to_form(user_params, as: "user")

        # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
        conn
        |> put_flash(:error, "Email ou mot de passe incorrect")
        |> render(:new, form: form)
    end
  end

  # magic link request
  def create(conn, %{"user" => %{"email" => email}}) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      "Si votre email est dans notre système, vous recevrez un lien de connexion dans quelques instants."

    conn
    |> put_flash(:info, info)
    |> redirect(to: ~p"/users/log-in")
  end

  def confirm(conn, %{"token" => token}) do
    if user = Accounts.get_user_by_magic_link_token(token) do
      form = Phoenix.Component.to_form(%{"token" => token}, as: "user")

      conn
      |> assign(:user, user)
      |> assign(:form, form)
      |> render(:confirm)
    else
      conn
      |> put_flash(:error, "Ce lien de connexion est invalide ou a expiré.")
      |> redirect(to: ~p"/users/log-in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Déconnexion réussie. À bientôt !")
    |> UserAuth.log_out_user()
  end
end
