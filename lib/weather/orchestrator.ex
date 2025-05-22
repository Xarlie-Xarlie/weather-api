defmodule Weather.Orchestrator do
  @moduledoc """
  A module responsible for orchestrating weather data requests. It initializes
  the request process, spawns worker processes for each location, and collects
  the results when all workers complete their tasks.
  """

  alias Weather.Storage
  alias Weather.Worker

  require Logger

  @default_timeout 10_000

  @doc """
  Starts a weather data request for a list of locations.

  ## Parameters
    - `locations`: A list of maps, where each map contains location details
      (e.g., latitude, longitude, state).
    - `opts`: A keyword list of options:
      - `:timeout` - The timeout in milliseconds (default: 10,000)

  ## Returns
    - `{:ok, results}`: A tuple containing the results when all requests are completed.
    - `{:error, :timeout}`: A tuple indicating a timeout if the requests do not complete
      within the specified time.
    - `{:error, reason}`: A tuple containing the error reason if the request fails.

  ## Example
      locations = [
        %{location: "São Paulo", latitude: -23.55, longitude: -46.63},
        %{location: "Belo Horizonte", latitude: -19.92, longitude: -43.94}
      ]

      Weather.Orchestrator.start_request(locations)
  """
  @spec start_request([map()], keyword()) :: {:ok, any()} | {:error, any()}
  def start_request(locations, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    pid = self()
    total_requests = length(locations)

    {:ok, request_id} = Storage.init_request(pid, total_requests)

    start_workers(locations, request_id)

    receive do
      {:results_ready, ^request_id, results} ->
        {:ok, results}

      {:request_timeout, ^request_id} ->
        {:error, :timeout}
    after
      timeout ->
        {:error, :timeout}
    end
  end

  @spec start_workers([map()], String.t()) :: :ok
  defp start_workers(locations, request_id) do
    Enum.each(locations, fn location ->
      Task.Supervisor.start_child(Weather.TaskSupervisor, fn ->
        try do
          Worker.perform_request(request_id, location)
        rescue
          e ->
            Logger.error("Worker crashed for #{location.location}: #{inspect(e)}")

            Storage.update_request(request_id, %{
              error: "Worker crashed",
              location: location.location
            })
        end
      end)
    end)
  end
end
