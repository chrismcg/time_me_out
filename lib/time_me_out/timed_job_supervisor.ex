defmodule TimeMeOut.TimedJobSupervisor do
  use Supervisor

  def perform_job(some_job_arg, job_timeout \\ 5000) do
    {:ok, worker_pid} = Supervisor.start_child(__MODULE__, [])
    TimeMeOut.TimedJob.perform_job(worker_pid, some_job_arg, job_timeout)
  end

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children = [
      worker(TimeMeOut.TimedJob, [], restart: :temporary, shutdown: :brutal_kill)
    ]

    opts = [strategy: :simple_one_for_one]

    supervise(children, opts)
  end
end
