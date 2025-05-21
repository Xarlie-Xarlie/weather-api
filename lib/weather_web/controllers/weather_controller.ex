defmodule WeatherWeb.WeatherController do
  use WeatherWeb, :controller

  def show(conn, _params) do
    weather_data = %{
      "São Paulo" => "28.5°C",
      "Belo Horizonte" => "27.8°C",
      "Curitiba" => "22.1°C"
    }

    json(conn, weather_data)
  end
end
