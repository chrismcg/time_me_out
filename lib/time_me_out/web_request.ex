defmodule TimeMeOut.WebRequest do
  use GenServer

  defstruct reply_sent: false, from: nil, reply_data: %{}, db_data: %{}, handler_pid: nil

  # Client
  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def handle_request(worker_pid, params, reply_timeout, worker_timeout) do
    GenServer.call(worker_pid, {:handle_request, params, reply_timeout, worker_timeout})
  end

  # Server Callbacks
  def init([]) do
    {:ok, %TimeMeOut.WebRequest{}}
  end

  # This is the entry point to the process. It's handle_call as it's called
  # from the client API method which waits for it to reply so it can create the
  # web html/json response which needs to wait around for the information
  def handle_call({:handle_request, params, reply_timeout, worker_timeout}, from, state) do
    IO.puts "Received request with #{inspect params}"
    # send ourselves a message after reply_timeout ms
    Process.send_after(self, :send_reply, reply_timeout)
    # send ourselves a message after worker_timeout ms
    Process.send_after(self, :terminate_worker, worker_timeout)

    # Start another process to handle talking to the external service
    {:ok, handler_pid} = TimeMeOut.ZeromqWorker.start_link(self, params)

    # Store the pid who called us (from) and the pid of our handler in the state
    state = %{state | from: from, handler_pid: handler_pid}

    # Don't reply to the client but finish the function so we can receive messages again
    { :noreply, state }
  end

  # This function handles data from the handler "zeromq" process It updates the
  # internal state depending on whether we've sent a reply to the client or not
  def handle_info({:data, id, value}, state) do
    if state.reply_sent do
      IO.puts "Received post reply data: #{id}: #{value}"
      state = %{state | db_data: Map.put(state.db_data, id, value)}
    else
      IO.puts "Received pre reply data: #{id}: #{value}"
      state = %{state | reply_data: Map.put(state.reply_data, id, value)}
    end
    {:noreply, state}
  end

  # We get this message after the reply_timeout has passed, so we reply to the
  # client with the information we have so far
  def handle_info(:send_reply, state) do
    IO.puts "Reply timeout: Sending reply #{inspect state.reply_data}"
    GenServer.reply(state.from, state.reply_data)
    state = %{state | reply_sent: true}
    {:noreply, state}
  end

  # We get this message after the worker_timeout has passed, here's where we'd
  # put whatever else we'd got into the db
  def handle_info(:terminate_worker, state) do
    IO.puts "Worker timeout: data for db #{inspect state.db_data}"
    # write to db somehow
    {:stop, :normal, state}
  end

  # This function only exists so we can print out some debugging info, it's
  # not really needed
  def terminate(_reason, state) do
    IO.puts "terminating WebRequest #{Process.alive?(state.handler_pid)}"
    :ok
  end
end
