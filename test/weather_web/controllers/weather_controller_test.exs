defmodule WeatherWeb.WeatherControllerTest do
  use WeatherWeb.ConnCase, async: false
  import Mox

  alias Weather.ClientMock

  setup :verify_on_exit!
  setup :set_mox_from_context

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

    assert json_response(conn, 200) ==
             [
               "Parameter 'latitude' and 'longitude' must have the same number of elements",
               "Parameter 'latitude' and 'longitude' must have the same number of elements",
               "Parameter 'latitude' and 'longitude' must have the same number of elements"
             ]

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
             &(&1 === "Parameter 'latitude' and 'longitude' must have the same number of elements")
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

    assert json_response(conn, 200) == [
             "Request failed with status Latitude must be in range of -90 to 90°. Given: -2e+12.",
             "Request failed with status Latitude must be in range of -90 to 90°. Given: -2e+12.",
             "Request failed with status Latitude must be in range of -90 to 90°. Given: -2e+12."
           ]

    assert_receive {^ref, :temp}

    verify!()
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
