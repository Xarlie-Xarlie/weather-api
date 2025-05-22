defmodule Weather.OrchestratorTest do
  use ExUnit.Case, async: false
  import Mox

  alias Weather.Orchestrator
  alias Weather.ClientMock

  setup do
    verify_on_exit!()
    :ok
  end

  describe "start_request/2" do
    test "successfully processes all locations" do
      Mox.allow(ClientMock, self(), Process.whereis(Weather.TaskSupervisor))

      ClientMock
      |> expect(:call, 3, fn params ->
        case params.location do
          "São Paulo" -> {:ok, [25.0, 25.0, 25.0, 25.0, 25.0, 25.0]}
          "Belo Horizonte" -> {:ok, [22.0, 22.0, 22.0, 22.0, 22.0, 22.0]}
          "Curitiba" -> {:ok, [18.0, 18.0, 18.0, 18.0, 18.0, 18.0]}
        end
      end)

      locations = [
        %{location: "São Paulo", latitude: -23.55, longitude: -46.63},
        %{location: "Belo Horizonte", latitude: -19.92, longitude: -43.94},
        %{location: "Curitiba", latitude: -25.43, longitude: -49.27}
      ]

      {:ok, results} = Orchestrator.start_request(locations)

      assert length(results) == 3
      assert Enum.any?(results, fn result -> result == %{"São Paulo" => "25.0°C"} end)
      assert Enum.any?(results, fn result -> result == %{"Belo Horizonte" => "22.0°C"} end)
      assert Enum.any?(results, fn result -> result == %{"Curitiba" => "18.0°C"} end)
    end

    test "handles worker errors" do
      Mox.allow(ClientMock, self(), Process.whereis(Weather.TaskSupervisor))

      ClientMock
      |> expect(:call, 5, fn params ->
        case params.location do
          "São Paulo" -> {:ok, [25.0, 25.0, 25.0, 25.0, 25.0, 25.0]}
          "Belo Horizonte" -> raise "API unavailable"
          "Curitiba" -> {:ok, [18.0, 18.0, 18.0, 18.0, 18.0, 18.0]}
        end
      end)

      locations = [
        %{location: "São Paulo", latitude: -23.55, longitude: -46.63},
        %{location: "Belo Horizonte", latitude: -19.92, longitude: -43.94},
        %{location: "Curitiba", latitude: -25.43, longitude: -49.27}
      ]

      {:ok, results} = Orchestrator.start_request(locations)

      assert length(results) == 3
      assert Enum.any?(results, fn result -> result == %{"São Paulo" => "25.0°C"} end)

      assert Enum.any?(results, fn result ->
               result == %{error: "Max retries exceeded", location: "Belo Horizonte"}
             end)

      assert Enum.any?(results, fn result -> result == %{"Curitiba" => "18.0°C"} end)
    end

    test "handles timeout" do
      locations = [
        %{location: "São Paulo", latitude: -23.55, longitude: -46.63}
      ]

      ClientMock
      |> expect(:call, fn _params ->
        Process.sleep(500)
        {:ok, [25.0, 25.0, 25.0, 25.0, 25.0, 25.0]}
      end)

      result = Orchestrator.start_request(locations, timeout: 100)

      assert result == {:error, :timeout}
    end
  end
end
