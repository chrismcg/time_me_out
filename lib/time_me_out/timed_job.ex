defmodule TimeMeOut.TimedJob do
  use GenServer

  # Client

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def perform_job(worker_pid, some_job_arg, job_timeout) do
    GenServer.call(worker_pid, {:perform_job, some_job_arg}, job_timeout)
  end

  # Server Callbacks
  def init([]) do
    :random.seed :erlang.phash2([node]),
      :erlang.monotonic_time,
      :erlang.unique_integer

    job_id = :erlang.unique_integer
      |> :erlang.phash2
      |> Integer.to_string(16)

    {:ok, job_id }
  end

  def handle_call({:perform_job, _some_job_arg}, _from, job_id) do
    if :random.uniform > 0.5 do
      IO.puts "#{job_id}: Sleeping long enough to trigger timeout"
      :timer.sleep(10_000)
    else
      IO.puts "#{job_id}: Sleeping short enough not to trigger timeout"
      :timer.sleep(1_000)
    end

    { :stop, :normal, {:ok, "some return value"}, job_id}
  end
end
