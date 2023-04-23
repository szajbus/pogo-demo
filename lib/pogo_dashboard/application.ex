defmodule PogoDashboard.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    :ok = LocalCluster.start()

    nodes =
      LocalCluster.start_nodes("test-app-", 3, applications: [:test_app], files: ["lib/worker.ex"])

    for node <- nodes do
      {:ok, _pid} = :rpc.call(node, TestApp, :start_pogo, [])
    end

    for i <- 1..20 do
      child_spec = Worker.child_spec(i)

      nodes
      |> Enum.random()
      |> :rpc.call(TestApp, :start_child, [child_spec])
    end

    children = [
      # Start the Telemetry supervisor
      PogoDashboardWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: PogoDashboard.PubSub},
      # Start the Endpoint (http/https)
      PogoDashboardWeb.Endpoint,
      # Start a worker by calling: PogoDashboard.Worker.start_link(arg)
      # {PogoDashboard.Worker, arg},
      %{id: {:pg, :test}, start: {:pg, :start_link, [:test]}}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PogoDashboard.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PogoDashboardWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
