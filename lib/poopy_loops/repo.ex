defmodule PoopyLoops.Repo do
  use Ecto.Repo,
    otp_app: :poopy_loops,
    adapter: Ecto.Adapters.Postgres
end
