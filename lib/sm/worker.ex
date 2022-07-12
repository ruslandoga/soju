defmodule Sm.Worker do
  @moduledoc false
  @callback perform(%Sm.Job{}) :: :ok | :discard | {:error, any}

  defmacro __using__(_opts) do
    quote do
      @behaviour Sm.Worker
    end
  end
end
