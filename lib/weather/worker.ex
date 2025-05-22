defmodule Weather.Worker do
  @moduledoc """
  A module responsible for performing weather-related tasks, such as making API requests
  and processing location data.
  """

  alias Weather.Storage
  alias Weather.HttpClientImpl, as: HttpClientImpl

  @doc """
  Performs a weather request for a given process ID (`pid`) and location.

  ## Parameters
    - `pid`: The process ID to associate the request with.
    - `location`: A map containing location details (e.g., latitude, longitude).

  ## Returns
    - `:ok` after updating the storage with the result.
  """
  @spec perform_request(pid(), map()) :: :ok
  def perform_request(pid, location) do
    result =
      add_location_info(location)
      |> call_api

    Storage.update_request(pid, result)
  end

  @spec add_location_info(map()) :: map()
  defp add_location_info(location) do
    location
    |> Map.put(:daily, "temperature_2m_max")
    |> Map.put(:timezone, "America/Sao_Paulo")
  end

  @spec call_api(map()) :: map() | String.t()
  defp call_api(location) do
    client().call(location)
    |> case do
      {:ok, temperatures} ->
        calculate_mean_temperature(temperatures)
        |> then(&Map.new([{location.state, "#{&1}°C"}]))

      {:error, reason} ->
        reason
    end
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
