defmodule TimeMeOut.WebRequestSupervisor do
  use Supervisor

  def handle_request(params, reply_timeout \\ 200, worker_timeout \\ 1000) do
    {:ok, worker_pid} = Supervisor.start_child(__MODULE__, [])
    TimeMeOut.WebRequest.handle_request(worker_pid, params, reply_timeout, worker_timeout)
  end

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children = [
      worker(TimeMeOut.WebRequest, [])
    ]

    opts = [strategy: :simple_one_for_one]

    supervise(children, opts)
  end
end
