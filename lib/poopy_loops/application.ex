defmodule PoopyLoops.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PoopyLoopsWeb.Telemetry,
      PoopyLoops.Repo,
      {DNSCluster, query: Application.get_env(:poopy_loops, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PoopyLoops.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: PoopyLoops.Finch},
      # Start a worker by calling: PoopyLoops.Worker.start_link(arg)
      # {PoopyLoops.Worker, arg},
      # Start to serve requests, typically the last entry
      PoopyLoopsWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PoopyLoops.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PoopyLoopsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
