defmodule Weather.HttpClientImpl do
  @moduledoc """
  Implementation of the `Weather.HttpClient` behaviour using the Tesla HTTP client.

  This module is responsible for making HTTP requests to the Open-Meteo API
  to fetch weather forecast data.
  """

  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://api.open-meteo.com/v1"
  plug Tesla.Middleware.JSON

  @behaviour Weather.HttpClient

  @doc """
  Makes a request to the Open-Meteo API with the given parameters.

  ## Parameters
    - `params`: A map of query parameters to include in the API request.

  ## Returns
    - `{:ok, list}`: A tuple containing the list of maximum temperatures for the next 6 days.
    - `{:error, reason}`: A tuple containing the error reason if the request fails.
  """
  @spec call(map()) :: {:ok, list()} | {:error, String.t()}
  @impl Weather.HttpClient
  def call(params) do
    Enum.into(params, [])
    |> then(&get("/forecast/", query: &1))
    |> handle_response()
  end

  @spec handle_response({:ok, Tesla.Env.t()} | {:error, Tesla.Env.t()} | any()) ::
          {:ok, list()} | {:error, String.t()}
  defp handle_response(
         {:ok,
          %Tesla.Env{
            status: 200,
            body: %{"daily" => %{"temperature_2m_max" => temperature_2m_max}}
          }}
       ) do
    {:ok, Enum.take(temperature_2m_max, 6)}
  end

  defp handle_response({:ok, %Tesla.Env{body: %{"reason" => reason}}}) do
    {:error, reason}
  end

  defp handle_response({:error, %Tesla.Env{body: %{"reason" => reason}}}) do
    {:error, reason}
  end

  defp handle_response(_) do
    {:error, "Request failed"}
  end
end
