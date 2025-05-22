defmodule Weather.Worker do
  @moduledoc """
  A module responsible for performing weather-related tasks, such as making API requests
  and processing location data.
  """

  alias Weather.Storage
  alias Weather.HttpClientImpl, as: HttpClientImpl

  require Logger

  @max_retries 3
  @retry_delay 1000

  @doc """
  Performs a weather request for a given request ID and location.

  ## Parameters
    - `request_id`: The unique ID of the request.
    - `location`: A map containing location details (e.g., latitude, longitude).

  ## Returns
    - `:ok` after updating the storage with the result.
  """
  @spec perform_request(String.t(), map()) :: :ok
  def perform_request(request_id, location) do
    result =
      add_location_info(location)
      |> call_api_with_retry(0)

    Storage.update_request(request_id, result)
  end

  @spec add_location_info(map()) :: map()
  defp add_location_info(location) do
    location
    |> Map.put(:daily, "temperature_2m_max")
    |> Map.put(:timezone, "America/Sao_Paulo")
  end

  @spec call_api_with_retry(map(), non_neg_integer()) :: map()
  defp call_api_with_retry(location, retry_count) when retry_count < @max_retries do
    try do
      client().call(location)
      |> case do
        {:ok, temperatures} ->
          calculate_mean_temperature(temperatures)
          |> then(&Map.new([{location.state, "#{&1}°C"}]))

        {:error, reason} ->
          %{error: reason, location: location.state}
      end
    rescue
      e ->
        Logger.error(
          "Exception in API call for #{location.state}: #{inspect(e)}. Retry #{retry_count + 1}/#{@max_retries}"
        )

        Process.sleep(@retry_delay)
        call_api_with_retry(location, retry_count + 1)
    end
  end

  defp call_api_with_retry(location, _retry_count) do
    %{error: "Max retries exceeded", location: location.state}
  end

  @spec calculate_mean_temperature([float()]) :: number()
  defp calculate_mean_temperature(temperatures) do
    Enum.reduce(temperatures, {0, 0}, fn temperature, {acc_temp, qty} ->
      {temperature + acc_temp, qty + 1}
    end)
    |> case do
      {_, 0} -> 0
      {temp, qty} -> Float.round(temp / qty, 1)
    end
  end

  @spec client() :: module()
  defp client(), do: Application.get_env(:weather, :client, HttpClientImpl)
end
