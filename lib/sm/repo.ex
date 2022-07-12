defmodule Sm.Repo do
  use Ecto.Repo, otp_app: :salaryman, adapter: Ecto.Adapters.SQLite3
end
