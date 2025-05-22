defmodule Weather.Orchestrator do
  @moduledoc """
  A module responsible for orchestrating weather data requests. It initializes
  the request process, spawns worker processes for each location, and collects
  the results when all workers complete their tasks.
  """
  alias Weather.Storage
  alias Weather.Worker

  @doc """
  Starts a weather data request for a list of locations.

  ## Parameters
    - `locations`: A list of maps, where each map contains location details
      (e.g., latitude, longitude, state).

  ## Returns
    - `{:ok, results}`: A tuple containing the results when all requests are completed.
    - `{:error, :timeout}`: A tuple indicating a timeout if the requests do not complete
      within the specified time.

  ## Example
      locations = [
        %{state: "São Paulo", latitude: -23.55, longitude: -46.63},
        %{state: "Belo Horizonte", latitude: -19.92, longitude: -43.94}
      ]

      Weather.Orchestrator.start_request(locations)
  """
  @spec start_request([map()]) :: {:ok, any()} | {:error, :timeout}
  def start_request(locations) do
    pid = self()
    total_requests = length(locations)

    Storage.init_request(pid, total_requests)

    Enum.each(locations, fn location ->
      spawn(Worker, :perform_request, [pid, location])
    end)

    receive do
      {:results_ready, results} ->
        {:ok, results}
    after
      10_000 -> {:error, :timeout}
    end
  end
end
