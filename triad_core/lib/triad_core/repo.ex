defmodule TriadCore.Repo do
  use Ecto.Repo,
    otp_app: :triad_core,
    adapter: Ecto.Adapters.Postgres
end
