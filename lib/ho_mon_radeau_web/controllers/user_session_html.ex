defmodule HoMonRadeauWeb.UserSessionHTML do
  use HoMonRadeauWeb, :html

  embed_templates "user_session_html/*"

  defp local_mail_adapter? do
    Application.get_env(:ho_mon_radeau, HoMonRadeau.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
