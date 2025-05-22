defmodule Weather do
  @moduledoc """
  Entry point for weather-related operations.

  This module serves as an abstraction layer that interacts with the orchestrator
  to fetch weather data for predefined locations or custom locations. It hides 
  the underlying implementation details from the caller, providing a clean and 
  simple interface.
  """

  alias Weather.Orchestrator
  require Logger

  @locations [
    %{location: "São Paulo", latitude: -23.55, longitude: -46.63},
    %{location: "Belo Horizonte", latitude: -19.92, longitude: -43.94},
    %{location: "Curitiba", latitude: -25.43, longitude: -49.27}
  ]

  @doc """
  Fetches weather data for predefined or custom locations.

  ## Parameters
    - `opts`: A keyword list of options:
      - `:locations` - A list of custom location maps to fetch weather data for.
        Each map should have `:location`, `:latitude`, and `:longitude` keys.
      - `:timeout` - The timeout in milliseconds (default: 10,000).

  ## Returns
    - `{:ok, results}`: A tuple containing the weather data for all locations.
    - `{:error, reason}`: A tuple containing the error reason if the request fails.
  """
  @spec call(keyword()) :: {:ok, list()} | {:error, any()}
  def call(opts \\ []) do
    locations = Keyword.get(opts, :locations, @locations)
    timeout = Keyword.get(opts, :timeout, 10_000)

    Logger.info("Starting weather data request for #{length(locations)} locations")
    start_time = System.monotonic_time(:millisecond)

    result = Orchestrator.start_request(locations, timeout: timeout)

    end_time = System.monotonic_time(:millisecond)
    Logger.info("Weather data request completed in #{end_time - start_time}ms")

    result
  end
end
