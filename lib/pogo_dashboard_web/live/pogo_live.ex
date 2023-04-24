defmodule PogoDashboardWeb.PogoLive do
  use PogoDashboardWeb, :live_view

  alias PogoDashboard.Manager

  defmodule Child do
    defstruct [:id, :start_child, :terminate_child, :spec, :supervisor, :pid, :terminating]
  end

  @scope :test
  @update_interval 100

  def mount(_params, _, socket) do
    socket =
      socket
      |> assign(:supervisors, %{})

    socket =
      if connected?(socket) do
        Process.send_after(self(), :update, @update_interval)
        assign_data(socket)
      else
        socket
      end

    {:ok, socket}
  end

  def handle_info(:update, socket) do
    socket = assign_data(socket)
    Process.send_after(self(), :update, @update_interval)
    {:noreply, socket}
  end

  def handle_event(
        "start_nodes",
        %{"amount" => amount, "sync_interval" => sync_interval},
        socket
      ) do
    amount = String.to_integer(amount)
    sync_interval = String.to_integer(sync_interval)
    Manager.start_nodes(amount, sync_interval)
    {:noreply, socket}
  end

  def handle_event("stop_node", %{"node" => node}, socket) do
    node = String.to_atom(node)
    Manager.stop_node(node)
    {:noreply, socket}
  end

  def handle_event("start_workers", %{"amount" => amount}, socket) do
    amount = String.to_integer(amount)
    Manager.start_workers(amount)
    {:noreply, socket}
  end

  def handle_event("terminate_worker", %{"id" => id, "node" => node}, socket) do
    id = String.to_integer(id)
    node = String.to_atom(node)
    Manager.terminate_worker(node, {Worker, id})
    {:noreply, socket}
  end

  defp assign_data(socket) do
    children =
      @scope
      |> :pg.which_groups()
      |> Enum.reduce(%{}, fn {key, value} = group, children ->
        id =
          case value do
            %{id: id} -> id
            id -> id
          end

        nodes =
          @scope
          |> :pg.get_members(group)
          |> Enum.map(&node/1)

        nodes
        |> Enum.reduce(children, fn node, children ->
          child = struct(Child, [{:id, id}, {key, value}])

          update_in(children, [node], fn
            nil ->
              %{id => child}

            children ->
              Map.update(children, id, child, &Map.put(&1, key, value))
          end)
        end)
      end)

    children =
      children
      |> Enum.map(fn {node, children} ->
        {node, children |> Map.values() |> Enum.sort()}
      end)

    socket
    |> assign(:supervisors, children)
  end

  defp format_node(node) do
    node
    |> to_string()
    |> String.replace_prefix(":", "")
    |> String.replace_leading("\"", "")
    |> String.replace_trailing("\"", "")
  end
end
