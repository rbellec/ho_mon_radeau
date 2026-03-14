defmodule HoMonRadeauWeb.PageController do
  use HoMonRadeauWeb, :controller

  alias HoMonRadeau.Events

  def home(conn, _params) do
    case conn.assigns[:current_scope] do
      %{user: user} ->
        edition = Events.get_current_edition()
        user_crew = Events.get_user_crew(user)

        raft =
          if user_crew do
            Events.get_raft!(user_crew.raft_id)
          else
            nil
          end

        form_status =
          if edition && user_crew do
            Events.registration_form_status(user, edition.id)
          else
            nil
          end

        conn
        |> assign(:user_crew, user_crew)
        |> assign(:raft, raft)
        |> assign(:edition, edition)
        |> assign(:form_status, form_status)
        |> render(:home)

      _ ->
        conn
        |> assign(:user_crew, nil)
        |> assign(:raft, nil)
        |> assign(:edition, nil)
        |> assign(:form_status, nil)
        |> render(:home)
    end
  end
end
