defmodule Soju.Repo do
  use Ecto.Repo, otp_app: :soju, adapter: Ecto.Adapters.SQLite3
end
