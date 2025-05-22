defmodule Weather.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      WeatherWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:weather, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Weather.PubSub},
      # Start a worker by calling: Weather.Worker.start_link(arg)
      {Weather.Storage, nil},
      # Start to serve requests, typically the last entry
      WeatherWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Weather.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WeatherWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
