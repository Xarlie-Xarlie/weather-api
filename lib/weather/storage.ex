defmodule Weather.Storage do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init_request(pid, total_requests) do
    GenServer.call(__MODULE__, {:init_request, pid, total_requests})
  end

  def update_request(pid, data) do
    GenServer.cast(__MODULE__, {:update_request, pid, data})
  end

  def get_results(pid) do
    GenServer.call(__MODULE__, {:get_results, pid})
  end

  # Server Callbacks
  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:init_request, pid, total_requests}, _from, state) do
    new_state =
      Map.put(state, pid, %{data: [], total_requests: total_requests, completed_requests: 0})

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:get_results, pid}, _from, state) do
    {:reply, Map.get(state, pid, %{data: []}).data, state}
  end

  @impl true
  def handle_cast({:update_request, pid, data}, state) do
    case Map.get(state, pid) do
      nil ->
        {:noreply, state}

      %{data: current_data, total_requests: total, completed_requests: completed} = request_state ->
        updated_state =
          %{
            request_state
            | data: [data | current_data],
              completed_requests: completed + 1
          }

        new_state =
          if updated_state.completed_requests == total do
            # Notify the orchestrator when all requests are complete
            send(pid, {:results_ready, updated_state.data})
            Map.delete(state, pid)
          else
            Map.put(state, pid, updated_state)
          end

        {:noreply, new_state}
    end
  end
end
