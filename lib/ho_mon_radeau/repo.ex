defmodule HoMonRadeau.Repo do
  use Ecto.Repo,
    otp_app: :ho_mon_radeau,
    adapter: Ecto.Adapters.Postgres
end
