defmodule Mix.Tasks.Weather.FetchTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  import Mox

  alias Weather.ClientMock

  setup do
    Mox.allow(Weather.MockHttpClient, self(), Process.whereis(Weather.TaskSupervisor))
    verify_on_exit!()
    :ok
  end

  test "fetches weather data and displays as JSON" do
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
end
