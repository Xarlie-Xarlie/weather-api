defmodule WeatherWeb.WeatherControllerTest do
  use WeatherWeb.ConnCase, async: false
  import Mox

  alias Weather.ClientMock

  setup :verify_on_exit!
  setup :set_mox_from_context

  describe "GET /api/weather" do
    test "GET /api/weather returns weather data", %{conn: conn} do
      parent = self()
      ref = make_ref()

      expect(ClientMock, :call, 3, fn _data ->
        send(parent, {ref, :temp})
        success_data()
      end)

      conn = get(conn, "/api/weather")

      response = json_response(conn, 200)

      assert Enum.any?(response, &Map.equal?(&1, %{"São Paulo" => "23.9°C"}))
      assert Enum.any?(response, &Map.equal?(&1, %{"Belo Horizonte" => "23.9°C"}))
      assert Enum.any?(response, &Map.equal?(&1, %{"Curitiba" => "23.9°C"}))

      assert_receive {^ref, :temp}

      verify!()
    end

    test "GET /api/weather returns missing data", %{conn: conn} do
      parent = self()
      ref = make_ref()

      expect(ClientMock, :call, 3, fn _data ->
        send(parent, {ref, :temp})
        missing_data()
      end)

      conn = get(conn, "/api/weather")

      response = json_response(conn, 200)

      assert Enum.any?(
               response,
               &Map.equal?(&1, %{
                 "error" =>
                   "Parameter 'latitude' and 'longitude' must have the same number of elements",
                 "location" => "São Paulo"
               })
             )

      assert Enum.any?(
               response,
               &Map.equal?(&1, %{
                 "error" =>
                   "Parameter 'latitude' and 'longitude' must have the same number of elements",
                 "location" => "Belo Horizonte"
               })
             )

      assert Enum.any?(
               response,
               &Map.equal?(&1, %{
                 "error" =>
                   "Parameter 'latitude' and 'longitude' must have the same number of elements",
                 "location" => "Curitiba"
               })
             )

      assert_receive {^ref, :temp}

      verify!()
    end

    test "GET/ api/weather return some missing data", %{conn: conn} do
      parent = self()
      ref = make_ref()

      expect(ClientMock, :call, 2, fn _data ->
        send(parent, {ref, :temp})
        missing_data()
      end)

      expect(ClientMock, :call, 1, fn _data ->
        send(parent, {ref, :temp})
        success_data()
      end)

      conn = get(conn, "/api/weather")

      response = json_response(conn, 200)

      assert Enum.any?(
               response,
               &(Map.get(&1, "error") ===
                   "Parameter 'latitude' and 'longitude' must have the same number of elements")
             )

      assert Enum.any?(response, fn
               %{"Curitiba" => "23.9°C"} -> true
               %{"São Paulo" => "23.9°C"} -> true
               %{"Belo Horizonte" => "23.9°C"} -> true
               _ -> false
             end)

      assert_receive {^ref, :temp}

      verify!()
    end

    test "GET /api/weather returns out of range data", %{conn: conn} do
      parent = self()
      ref = make_ref()

      expect(ClientMock, :call, 3, fn _data ->
        send(parent, {ref, :temp})
        out_of_range_data()
      end)

      conn = get(conn, "/api/weather")

      response = json_response(conn, 200)

      assert Enum.any?(
               response,
               &Map.equal?(&1, %{
                 "error" =>
                   "Request failed with status Latitude must be in range of -90 to 90°. Given: -2e+12.",
                 "location" => "São Paulo"
               })
             )

      assert Enum.any?(
               response,
               &Map.equal?(&1, %{
                 "error" =>
                   "Request failed with status Latitude must be in range of -90 to 90°. Given: -2e+12.",
                 "location" => "Belo Horizonte"
               })
             )

      assert Enum.any?(
               response,
               &Map.equal?(&1, %{
                 "error" =>
                   "Request failed with status Latitude must be in range of -90 to 90°. Given: -2e+12.",
                 "location" => "Curitiba"
               })
             )

      assert_receive {^ref, :temp}

      verify!()
    end
  end

  describe "POST /api/weather/custom" do
    test "returns weather data for custom locations", %{conn: conn} do
      ClientMock
      |> expect(:call, 2, fn params ->
        case params.location do
          "New York" -> {:ok, [20.0, 20.0, 20.0, 20.0, 20.0, 20.0]}
          "London" -> {:ok, [15.0, 15.0, 15.0, 15.0, 15.0, 15.0]}
        end
      end)

      conn =
        post(conn, "/api/weather/custom", %{
          "locations" => [
            %{"location" => "New York", "latitude" => 40.71, "longitude" => -74.01},
            %{"location" => "London", "latitude" => 51.51, "longitude" => -0.13}
          ]
        })

      assert response = json_response(conn, 200)
      assert length(response) == 2
      assert Enum.any?(response, fn item -> item["New York"] == "20.0°C" end)
      assert Enum.any?(response, fn item -> item["London"] == "15.0°C" end)
    end

    test "returns error for invalid location data", %{conn: conn} do
      conn =
        post(conn, "/api/weather/custom", %{
          "locations" => [
            %{"location" => "New York", "latitude" => "not-a-number", "longitude" => -74.01}
          ]
        })

      assert json_response(conn, 400) == %{
               "error" =>
                 "Each location must have 'location' (string), 'latitude' (number), and 'longitude' (number)"
             }
    end

    test "returns error for missing locations parameter", %{conn: conn} do
      conn = post(conn, "/api/weather/custom", %{})

      assert json_response(conn, 400) == %{
               "error" => "Missing or invalid locations parameter"
             }
    end
  end

  defp success_data do
    {:ok, [25.4, 24.5, 21.3, 22.6, 23.8, 26.0]}
  end

  defp out_of_range_data do
    {:error, "Request failed with status Latitude must be in range of -90 to 90°. Given: -2e+12."}
  end

  defp missing_data do
    {:error, "Parameter 'latitude' and 'longitude' must have the same number of elements"}
  end
end
