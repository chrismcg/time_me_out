defmodule TimeMeOut do
  use Application

  def perform_job(some_job_arg, job_timeout \\ 5000) do
    TimeMeOut.TimedJobSupervisor.perform_job(some_job_arg, job_timeout)
  end

  def perform_job_async(some_job_arg, job_timeout \\ 5000) do
    Task.async(TimeMeOut.TimedJobSupervisor, :perform_job, [some_job_arg, job_timeout])
  end

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      supervisor(TimeMeOut.TimedJobSupervisor, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TimeMeOut.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
