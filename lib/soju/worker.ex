defmodule Soju.Worker do
  @moduledoc false
  @callback perform(%Soju.Job{}) :: :ok | :discard | {:error, any}

  defmacro __using__(_opts) do
    quote do
      @behaviour Soju.Worker
    end
  end
end
