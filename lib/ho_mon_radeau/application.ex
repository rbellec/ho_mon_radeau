defmodule HoMonRadeau.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      HoMonRadeauWeb.Telemetry,
      HoMonRadeau.Repo,
      {DNSCluster, query: Application.get_env(:ho_mon_radeau, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: HoMonRadeau.PubSub},
      # Start a worker by calling: HoMonRadeau.Worker.start_link(arg)
      # {HoMonRadeau.Worker, arg},
      # Start to serve requests, typically the last entry
      HoMonRadeauWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HoMonRadeau.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HoMonRadeauWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
