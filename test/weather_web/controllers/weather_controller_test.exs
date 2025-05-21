defmodule WeatherWeb.WeatherControllerTest do
  use WeatherWeb.ConnCase, async: true

  test "GET /api/weather returns weather data", %{conn: conn} do
    conn = get(conn, "/api/weather")

    assert json_response(conn, 200) == %{
             "São Paulo" => "28.5°C",
             "Belo Horizonte" => "27.8°C",
             "Curitiba" => "22.1°C"
           }
  end
end
