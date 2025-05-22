defmodule Weather do
  alias WeatherOrchestrator

  @locations [
    %{state: "São Paulo", latitude: -23.55, longitude: -46.63},
    %{state: "Belo Horizonte", latitude: -19.92, longitude: -43.94},
    %{state: "Curitiba", latitude: -25.43, longitude: -49.27}
  ]

  def call do
    case WeatherOrchestrator.start_request(@locations) do
      {:ok, results} -> {:ok, results}
      {:error, reason} -> {:error, reason}
    end
  end
end
