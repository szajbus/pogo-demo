defmodule PogoDashboard.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    :ok = LocalCluster.start()

    children = [
      # Start the Telemetry supervisor
      PogoDashboardWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: PogoDashboard.PubSub},
      # Start the Endpoint (http/https)
      PogoDashboardWeb.Endpoint,
      # Start a worker by calling: PogoDashboard.Worker.start_link(arg)
      # {PogoDashboard.Worker, arg},
      %{id: {:pg, :test}, start: {:pg, :start_link, [:test]}},
      PogoDashboard.Manager
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
