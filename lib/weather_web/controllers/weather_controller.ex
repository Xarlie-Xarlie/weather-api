defmodule WeatherWeb.WeatherController do
  @moduledoc """
  Controller responsible for handling weather-related API requests.

  This module provides endpoints to fetch weather data for predefined locations
  or custom locations provided in the request.
  """

  use WeatherWeb, :controller

  alias Weather

  @doc """
  Handles the `GET /api/weather` request to fetch weather data for predefined locations.

  ## Parameters
    - `conn`: The connection struct.
    - `_params`: The request parameters (ignored in this case).

  ## Returns
    - A JSON response with the weather data if the request is successful.
    - A JSON response with an error message and a `400 Bad Request` status if the request fails.
  """
  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show(conn, _params) do
    with {:ok, weather_data} <- Weather.call() do
      json(conn, weather_data)
    else
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end

  @doc """
  Handles the `POST /api/weather/custom` request to fetch weather data for custom locations.

  ## Parameters
    - `conn`: The connection struct.
    - `params`: The request parameters, expected to include a "locations" key
      with an array of location data.

    - `locations`: A list of maps, each containing:
      - `location`: The name of the location (string).
      - `latitude`: The latitude of the location (number).
      - `longitude`: The longitude of the location (number).

  ## Returns
    - A JSON response with the weather data if the request is successful.
    - A JSON response with an error message and a `400 Bad Request` status if the request fails
      or the location data is invalid.
  """
  @spec custom(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def custom(conn, %{"locations" => locations}) do
    with {:ok, parsed_locations} <- validate_locations(locations),
         {:ok, weather_data} <- Weather.call(locations: parsed_locations) do
      json(conn, weather_data)
    else
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end

  def custom(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing or invalid locations parameter"})
  end

  @spec validate_locations(list()) :: {:ok, list(map())} | {:error, String.t()}
  defp validate_locations(locations) when is_list(locations) do
    validation_results = Enum.map(locations, &validate_location/1)

    case Enum.find(validation_results, &(elem(&1, 0) == :error)) do
      nil ->
        valid_locations = Enum.map(validation_results, fn {:ok, location} -> location end)
        {:ok, valid_locations}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp validate_locations(_), do: {:error, "Locations must be an array"}

  @spec validate_location(map()) :: {:ok, map()} | {:error, String.t()}
  defp validate_location(%{
         "location" => location,
         "latitude" => latitude,
         "longitude" => longitude
       })
       when is_binary(location) and (is_float(latitude) or is_integer(latitude)) and
              (is_float(longitude) or is_integer(longitude)) do
    {:ok,
     %{
       location: location,
       latitude: latitude,
       longitude: longitude
     }}
  end

  defp validate_location(_) do
    {:error,
     "Each location must have 'location' (string), 'latitude' (number), and 'longitude' (number)"}
  end
end
