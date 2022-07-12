defmodule Soju do
  @moduledoc File.read!("README.md")
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  alias Soju.Queue

  @impl true
  def init(_init_arg) do
    task_sup = __MODULE__.TaskSupervisor

    children = [
      # TODO get repo from caller?
      Soju.Repo,
      {Task.Supervisor, name: task_sup},
      {Queue, task_sup: task_sup}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def schedule(job) do
    Queue.schedule(job)
  end
end
