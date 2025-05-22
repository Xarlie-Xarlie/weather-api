defmodule Weather do
  @moduledoc """
  Entry point for weather-related operations.

  This module serves as an abstraction layer that interacts with the orchestrator
  to fetch weather data for predefined locations. It hides the underlying implementation
  details from the caller, providing a clean and simple interface.
  """

  alias Weather.Orchestrator
  require Logger

  @locations [
    %{state: "São Paulo", latitude: -23.55, longitude: -46.63},
    %{state: "Belo Horizonte", latitude: -19.92, longitude: -43.94},
    %{state: "Curitiba", latitude: -25.43, longitude: -49.27}
  ]

  @doc """
  Fetches weather data for predefined locations.

  This function delegates the request to the orchestrator, which handles the
  concurrent fetching of weather data for all locations.

  ## Returns
    - `{:ok, results}`: A tuple containing the weather data for all locations.
    - `{:error, reason}`: A tuple containing the error reason if the request fails.
  """
  @spec call(keyword()) :: {:ok, list()} | {:error, any()}
  def call(opts \\ []) do
    Logger.info("Starting weather data request")
    start_time = System.monotonic_time(:millisecond)

    result = Orchestrator.start_request(@locations, opts)

    end_time = System.monotonic_time(:millisecond)
    Logger.info("Weather data request completed in #{end_time - start_time}ms")

    result
  end
end
