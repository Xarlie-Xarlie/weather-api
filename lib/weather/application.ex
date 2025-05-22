defmodule Weather.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      WeatherWeb.Telemetry,
      {Weather.Storage, nil},
      {Task.Supervisor, name: Weather.TaskSupervisor},
      WeatherWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Weather.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    WeatherWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
