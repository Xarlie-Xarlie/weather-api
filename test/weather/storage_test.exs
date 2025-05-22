defmodule Weather.StorageTest do
  use ExUnit.Case, async: false

  alias Weather.Storage

  describe "init_request/2" do
    test "initializes a new request with the correct structure" do
      pid = self()
      {:ok, request_id} = Storage.init_request(pid, 3)

      assert is_binary(request_id)
      assert byte_size(request_id) == 36

      assert %{data: [], total_requests: 3, completed_requests: 0, pid: ^pid} =
               :sys.get_state(Storage) |> Map.get(request_id)
    end
  end

  describe "update_request/2" do
    test "updates the request with new data" do
      pid = self()
      {:ok, request_id} = Storage.init_request(pid, 3)

      :ok = Storage.update_request(request_id, %{"São Paulo" => "23.9°C"})

      state = :sys.get_state(Storage)
      request_data = Map.get(state, request_id)

      assert request_data.completed_requests == 1
      assert request_data.data == [%{"São Paulo" => "23.9°C"}]
    end

    test "notifies the process when all requests are complete" do
      pid = self()
      {:ok, request_id} = Storage.init_request(pid, 2)

      :ok = Storage.update_request(request_id, %{"São Paulo" => "23.9°C"})

      :ok = Storage.update_request(request_id, %{"Belo Horizonte" => "22.5°C"})

      assert_receive {:results_ready, ^request_id, data}

      assert Enum.member?(data, %{"São Paulo" => "23.9°C"})
      assert Enum.member?(data, %{"Belo Horizonte" => "22.5°C"})

      state = :sys.get_state(Storage)
      assert Map.get(state, request_id) == nil
    end

    test "handles updates for non-existent requests" do
      non_existent_id = UUID.uuid4()

      :ok = Storage.update_request(non_existent_id, %{"São Paulo" => "23.9°C"})

      state = :sys.get_state(Storage)
      refute Map.get(state, non_existent_id)
    end
  end

  describe "get_results/1" do
    test "returns the data for an existing request" do
      pid = self()
      {:ok, request_id} = Storage.init_request(pid, 2)

      :ok = Storage.update_request(request_id, %{"São Paulo" => "23.9°C"})

      results = Storage.get_results(request_id)

      assert results == [%{"São Paulo" => "23.9°C"}]
    end

    test "returns empty list for non-existent requests" do
      non_existent_id = UUID.uuid4()

      results = Storage.get_results(non_existent_id)

      assert results == []
    end
  end

  describe "cleanup mechanism" do
    test "removes stale requests" do
      pid = self()
      {:ok, request_id} = Storage.init_request(pid, 3)

      state = :sys.get_state(Storage)
      request_data = Map.get(state, request_id)
      old_timestamp = System.monotonic_time(:millisecond) - 35_000
      updated_request_data = %{request_data | timestamp: old_timestamp}
      updated_state = Map.put(state, request_id, updated_request_data)
      :sys.replace_state(Storage, fn _ -> updated_state end)

      send(Process.whereis(Storage), :cleanup)

      Process.sleep(100)

      new_state = :sys.get_state(Storage)
      assert Map.get(new_state, request_id) == nil

      assert_receive {:request_timeout, ^request_id}
    end
  end
end
