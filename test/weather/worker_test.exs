defmodule Weather.WorkerTest do
  use ExUnit.Case, async: false
  import Mox

  alias Weather.Worker
  alias Weather.ClientMock

  setup do
    verify_on_exit!()
    :ok
  end

  describe "perform_request/2" do
    test "processes location data and updates storage with successful result" do
      ClientMock
      |> expect(:call, fn params ->
        assert params.location == "São Paulo"
        assert params.daily == "temperature_2m_max"
        assert params.timezone == "America/Sao_Paulo"
        assert params.latitude == -23.55
        assert params.longitude == -46.63

        {:ok, [25.4, 24.5, 21.3, 22.6, 23.8, 26.0]}
      end)

      {:ok, request_id} = Weather.Storage.init_request(self(), 1)

      location = %{
        location: "São Paulo",
        latitude: -23.55,
        longitude: -46.63
      }

      Worker.perform_request(request_id, location)

      assert_receive {:results_ready, ^request_id, [data]}
      assert data == %{"São Paulo" => "23.9°C"}
    end

    test "handles API error response" do
      ClientMock
      |> expect(:call, fn _params ->
        {:error, "Parameter 'latitude' and 'longitude' must have the same number of elements"}
      end)

      {:ok, request_id} = Weather.Storage.init_request(self(), 1)

      location = %{
        location: "São Paulo",
        latitude: -23.55,
        longitude: -46.63
      }

      Worker.perform_request(request_id, location)

      assert_receive {:results_ready, ^request_id, [data]}

      assert data == %{
               error:
                 "Parameter 'latitude' and 'longitude' must have the same number of elements",
               location: "São Paulo"
             }
    end

    test "retries failed API calls" do
      ClientMock
      |> expect(:call, 2, fn _params -> raise "my mock error" end)
      |> expect(:call, fn _params -> {:ok, [25.0, 25.0, 25.0, 25.0, 25.0, 25.0]} end)

      {:ok, request_id} = Weather.Storage.init_request(self(), 1)

      location = %{
        location: "São Paulo",
        latitude: -23.55,
        longitude: -46.63
      }

      Worker.perform_request(request_id, location)

      assert_receive {:results_ready, ^request_id, [data]}
      assert data == %{"São Paulo" => "25.0°C"}
    end

    test "gives up after max retries" do
      ClientMock
      |> expect(:call, 3, fn _params -> raise "API unavailable" end)

      {:ok, request_id} = Weather.Storage.init_request(self(), 1)

      location = %{
        location: "São Paulo",
        latitude: -23.55,
        longitude: -46.63
      }

      Worker.perform_request(request_id, location)

      assert_receive {:results_ready, ^request_id, [data]}
      assert data == %{error: "Max retries exceeded", location: "São Paulo"}
    end
  end
end
