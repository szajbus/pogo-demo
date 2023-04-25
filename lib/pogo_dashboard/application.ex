defmodule PogoDemo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    :ok = LocalCluster.start()

    children = [
      # Start the Telemetry supervisor
      PogoDemoWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: PogoDemo.PubSub},
      # Start the Endpoint (http/https)
      PogoDemoWeb.Endpoint,
      # Start a worker by calling: PogoDemo.Worker.start_link(arg)
      # {PogoDemo.Worker, arg},
      %{id: {:pg, :test}, start: {:pg, :start_link, [:test]}},
      PogoDemo.Manager
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PogoDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PogoDemoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
