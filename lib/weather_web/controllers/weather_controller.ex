defmodule WeatherWeb.WeatherController do
  @moduledoc """
  Controller responsible for handling weather-related API requests.

  This module provides an endpoint to fetch weather data for predefined locations.
  It interacts with the `Weather` module to retrieve the data and formats the response
  as JSON.
  """

  use WeatherWeb, :controller

  alias Weather

  @doc """
  Handles the `GET /api/weather` request to fetch weather data.

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
end
