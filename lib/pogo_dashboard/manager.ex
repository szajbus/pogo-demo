defmodule PogoDemo.Manager do
  @moduledoc false

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    {:ok, {1, 1}}
  end

  def start_nodes(n, sync_interval) do
    GenServer.cast(__MODULE__, {:start_nodes, n, sync_interval})
  end

  def stop_node(node) do
    GenServer.cast(__MODULE__, {:stop_node, node})
  end

  def start_workers(n) do
    GenServer.cast(__MODULE__, {:start_workers, n})
  end

  def terminate_worker(node, id) do
    GenServer.cast(__MODULE__, {:terminate_worker, node, id})
  end

  @impl true
  def handle_cast({:start_nodes, n, sync_interval}, {node_idx, worker_idx}) do
    prefix = "node-#{node_idx}-"

    nodes =
      LocalCluster.start_nodes(prefix, n, applications: [:test_app], files: ["lib/worker.ex"])

    nodes |> IO.inspect()

    opts = [name: TestApp.DistributedSupervisor, scope: :test, sync_interval: sync_interval]

    for node <- nodes do
      {:ok, _pid} =
        :rpc.call(
          node,
          Supervisor,
          :start_child,
          [TestApp.Supervisor, {Pogo.DynamicSupervisor, opts}]
        )
    end

    {:noreply, {node_idx + 1, worker_idx}}
  end

  def handle_cast({:stop_node, node}, state) do
    LocalCluster.stop_nodes([node])
    {:noreply, state}
  end

  def handle_cast({:start_workers, n}, {node_idx, worker_idx}) do
    for idx <- worker_idx..(worker_idx + n - 1) do
      node = Node.list() |> Enum.random()
      child_spec = Worker.child_spec(idx)

      :rpc.call(
        node,
        Pogo.DynamicSupervisor,
        :start_child,
        [TestApp.DistributedSupervisor, child_spec]
      )
    end

    {:noreply, {node_idx, worker_idx + n}}
  end

  def handle_cast({:terminate_worker, node, id}, state) do
    :rpc.call(node, Pogo.DynamicSupervisor, :terminate_child, [TestApp.DistributedSupervisor, id])

    {:noreply, state}
  end
end
