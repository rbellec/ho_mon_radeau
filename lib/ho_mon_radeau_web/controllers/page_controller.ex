defmodule HoMonRadeauWeb.PageController do
  use HoMonRadeauWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
