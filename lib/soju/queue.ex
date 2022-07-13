defmodule Soju.Queue do
  @moduledoc false
  use GenServer

  import Ecto.{Query, Changeset}
  alias Soju.{Repo, Job}

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    task_sup = Keyword.fetch!(opts, :task_sup)
    {:ok, task_sup, {:continue, :poll}}
  end

  defmacrop json_insert(json, at, value) do
    quote do
      fragment("json_insert(?, ?, ?)", unquote(json), unquote(at), unquote(value))
    end
  end

  defmacrop json_append(json, value) do
    quote do
      json_insert(unquote(json), "$[#]", unquote(value))
    end
  end

  @impl true
  def handle_continue(:poll, task_sup) do
    # poll for jobs in db and try executing available ones
    # also do clean up if there are "executing" jobs right now in db
    jobs = poll()

    %{success: success, failure: failure, discard: discard} = execute(task_sup, jobs)

    # if they succeed, update their status
    Job
    |> where([j], j.id in ^Enum.map(success, & &1.id))
    |> Repo.update_all(set: [status: 2])

    # discarded are just removed
    Job
    |> where([j], j.id in ^Enum.map(discard, & &1.id))
    |> Repo.update_all(set: [status: 4])

    now = NaiveDateTime.utc_now()

    # if they fail, update errors, and reschedule
    # TODO use cte + single update
    Enum.each(failure, fn {reason, job} ->
      # 10, 40, 90, 160, 250, ... seconds
      next_scheduled_in = job.attempts * job.attempts * 10
      next_scheduled_at = NaiveDateTime.add(now, next_scheduled_in)
      Process.send_after(self(), :retry, :timer.seconds(next_scheduled_in))

      Job
      |> where(id: ^job.id)
      |> update([j], set: [errors: json_append(j.error, ^reason)])
      |> Repo.update_all(set: [status: 0, scheduled_at: next_scheduled_at])
    end)

    {:noreply, task_sup}
  end

  @impl true
  def handle_call({:schedule, job}, _from, task_sup) do
    job
    |> change()
    |> unique_constraint(:id)
    # insert job into db
    |> Repo.insert()
    |> case do
      {:ok, job} = success ->
        # try executing the job right away in a task
        # if it fails, it gets automatically rescheduled
        execute(task_sup, [job])
        {:reply, success, task_sup}

      {:error, %Ecto.Changeset{}} = failure ->
        {:reply, failure, task_sup}
    end
  end

  def poll do
    {_, jobs} =
      Job
      |> where(status: 0)
      |> select([j], j)
      # TODO is sattus = 1 used anywhere?
      |> update([j], set: [status: 1, attempts: j.attempts + 1])
      |> Repo.update_all([])

    jobs
  end

  def execute(task_sup, jobs) do
    task_sup
    |> Task.Supervisor.async_stream_nolink(
      jobs,
      fn job -> {perform(job), job} end,
      # TODO custom concurrency per queue
      max_concurrency: 10,
      ordered: false,
      # TODO
      on_timeout: :kill_task
      # TODO custom timeout per job?
    )
    |> Enum.reduce(%{success: [], failure: [], discard: []}, fn
      {:ok, {:ok, job}}, acc ->
        Map.update!(acc, :success, &[job | &1])

      {:ok, {:discard, job}}, acc ->
        Map.update!(acc, :discard, &[job | &1])

      {:ok, {{:error, reason}, job}}, acc ->
        Map.update!(acc, :failure, &[{reason, job} | &1])
    end)
  end

  # TODO ensure catches all possible errors
  def perform(%Job{worker: worker} = job) do
    try do
      mod = String.to_existing_atom(worker)

      case mod.perform(job) do
        :ok -> :ok
        :discard -> :discard
        {:error, _reason} = failure -> failure
        _other -> :ok
      end
    rescue
      e -> {:error, e}
    catch
      :exit, reason -> {:error, reason}
    end
  end
end

defmodule DemoJob do
  @moduledoc false
  use Soju.Worker

  @impl true
  def perform(%Soju.Job{args: args}) do
    IO.inspect(args, label: "DemoJob.args")
    :ok
  end
end
