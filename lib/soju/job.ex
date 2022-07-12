defmodule Soju.Job do
  @moduledoc false
  use Ecto.Schema

  @primary_key false
  schema "soju_jobs" do
    field :id, :binary, primary_key: true
    field :worker, :string
    field :status, :integer, default: 0
    field :errors, {:array, :map}, default: []
    field :attempts, :integer, default: 0
    field :scheduled_at, :naive_datetime
    field :args, :map
  end
end
