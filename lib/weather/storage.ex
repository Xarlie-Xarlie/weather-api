defmodule Weather.Storage do
  @moduledoc """
  A GenServer module responsible for managing the state of weather data requests.
  It tracks the progress of each request and notifies the orchestrator when all
  requests for a given process are complete.
  """

  use GenServer
  require Logger

  @cleanup_interval 60_000
  @request_timeout 30_000

  @spec start_link(any()) :: {:ok, pid()} | {:error, any()}
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @spec init_request(pid(), non_neg_integer()) :: {:ok, String.t()}
  @doc """
  Initializes a new request in the GenServer state.

  ## Parameters
    - `pid`: The PID of the process initiating the request.
    - `total_requests`: The total number of requests to track for this process.

  ## Returns
    - `{:ok, request_id}`: The unique ID for this request.
  """
  def init_request(pid, total_requests) do
    GenServer.call(__MODULE__, {:init_request, pid, total_requests})
  end

  @spec update_request(String.t(), any()) :: :ok
  @doc """
  Updates the state of a request with new data.

  ## Parameters
    - `request_id`: The unique ID of the request.
    - `data`: The data to add to the request's state.

  ## Returns
    - `:ok`: Indicates the state was successfully updated.
  """
  def update_request(request_id, data) do
    GenServer.cast(__MODULE__, {:update_request, request_id, data})
  end

  @spec get_results(String.t()) :: any()
  @doc """
  Retrieves the results of a request.

  ## Parameters
    - `request_id`: The unique ID of the request.

  ## Returns
    - `data`: The data collected for the request.
  """
  def get_results(request_id) do
    GenServer.call(__MODULE__, {:get_results, request_id})
  end

  @impl true
  @spec init(map()) :: {:ok, map()}
  def init(state) do
    schedule_cleanup()
    {:ok, state}
  end

  @impl true
  @spec handle_call({:init_request, pid(), non_neg_integer()}, any(), map()) ::
          {:reply, {:ok, String.t()}, map()}
  def handle_call({:init_request, pid, total_requests}, _from, state) do
    request_id = UUID.uuid4()
    timestamp = System.monotonic_time(:millisecond)

    new_state =
      Map.put(state, request_id, %{
        pid: pid,
        data: [],
        total_requests: total_requests,
        completed_requests: 0,
        timestamp: timestamp
      })

    {:reply, {:ok, request_id}, new_state}
  end

  @impl true
  @spec handle_call({:get_results, String.t()}, any(), map()) ::
          {:reply, any(), map()}
  def handle_call({:get_results, request_id}, _from, state) do
    case Map.get(state, request_id) do
      nil -> {:reply, [], state}
      request_data -> {:reply, request_data.data, state}
    end
  end

  @impl true
  @spec handle_cast({:update_request, String.t(), any()}, map()) ::
          {:noreply, map()}
  def handle_cast({:update_request, request_id, data}, state) do
    case Map.get(state, request_id) do
      nil ->
        Logger.warning("Attempted to update non-existent request: #{request_id}")
        {:noreply, state}

      %{pid: pid, data: current_data, total_requests: total, completed_requests: completed} =
          request_data ->
        updated_request_data = %{
          request_data
          | data: [data | current_data],
            completed_requests: completed + 1,
            timestamp: System.monotonic_time(:millisecond)
        }

        new_state =
          if updated_request_data.completed_requests == total do
            # Notify the orchestrator when all requests are complete
            send(pid, {:results_ready, request_id, updated_request_data.data})
            Map.delete(state, request_id)
          else
            Map.put(state, request_id, updated_request_data)
          end

        {:noreply, new_state}
    end
  end

  @impl true
  def handle_info(:cleanup, state) do
    current_time = System.monotonic_time(:millisecond)

    new_state =
      Enum.reduce(state, state, fn {request_id, request_data}, acc ->
        if current_time - request_data.timestamp > @request_timeout do
          if request_data.completed_requests < request_data.total_requests do
            Logger.warning(
              "Request timeout: #{request_id}, completed #{request_data.completed_requests}/#{request_data.total_requests}"
            )

            send(request_data.pid, {:request_timeout, request_id})
          end

          Map.delete(acc, request_id)
        else
          acc
        end
      end)

    schedule_cleanup()
    {:noreply, new_state}
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @cleanup_interval)
  end
end
