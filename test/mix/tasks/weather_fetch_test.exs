defmodule Mix.Tasks.Weather.FetchTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  import Mox

  alias Weather.ClientMock

  setup do
    Mox.allow(ClientMock, self(), Process.whereis(Weather.TaskSupervisor))
    verify_on_exit!()
    :ok
  end

  test "fetches weather data for predefined locations and displays as JSON" do
    ClientMock
    |> expect(:call, 3, fn _params ->
      {:ok, [25.0, 25.0, 25.0, 25.0, 25.0, 25.0]}
    end)

    output =
      capture_io(fn ->
        Mix.Tasks.Weather.Fetch.run([])
      end)

    {:ok, json} = Jason.decode(output)

    assert length(json) == 3
    assert Enum.any?(json, fn item -> Map.has_key?(item, "São Paulo") end)
    assert Enum.any?(json, fn item -> Map.has_key?(item, "Belo Horizonte") end)
    assert Enum.any?(json, fn item -> Map.has_key?(item, "Curitiba") end)
  end

  test "fetches weather data for custom locations from a JSON file" do
    file_path = "test/fixtures/locations.json"

    ClientMock
    |> expect(:call, 2, fn params ->
      case params.location do
        "New York" -> {:ok, [20.0, 20.0, 20.0, 20.0, 20.0, 20.0]}
        "London" -> {:ok, [15.0, 15.0, 15.0, 15.0, 15.0, 15.0]}
      end
    end)

    output =
      capture_io(fn ->
        Mix.Tasks.Weather.Fetch.run(["--locations=#{file_path}"])
      end)

    {:ok, json} = Jason.decode(output)

    assert length(json) == 2
    assert Enum.any?(json, fn item -> item["New York"] == "20.0°C" end)
    assert Enum.any?(json, fn item -> item["London"] == "15.0°C" end)
  end

  test "handles invalid JSON file" do
    file_path = "test/fixtures/invalid.json"

    assert_raise Mix.Error, ~r/Error reading locations file: Invalid JSON format/, fn ->
      capture_io(fn ->
        Mix.Tasks.Weather.Fetch.run(["--locations=#{file_path}"])
      end)
    end
  end

  test "handles invalid location data in JSON file" do
    file_path = "test/fixtures/invalid_locations.json"

    assert_raise Mix.Error, ~r/Error reading locations file: Each location must have/, fn ->
      capture_io(fn ->
        Mix.Tasks.Weather.Fetch.run(["--locations=#{file_path}"])
      end)
    end
  end

  test "handles non-existent JSON file" do
    assert_raise Mix.Error, ~r/Error reading locations file/, fn ->
      capture_io(fn ->
        Mix.Tasks.Weather.Fetch.run(["--locations=non_existent_file.json"])
      end)
    end
  end
end
