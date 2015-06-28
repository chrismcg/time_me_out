defmodule TimeMeOut.ZeromqWorker do
  use GenServer

  defstruct owner: nil, params: nil

  # Client API
  def start_link(owner, params) do
    GenServer.start_link(__MODULE__, [owner, params])
  end

  # Server callbacks
  def init([owner, params]) do
    # Need to trap exit so we get a message when WebRequest terminates
    # THIS IS IMPORTANT
    # Without this the process will hang around for too long. Honestly, I'm not
    # sure why yet but I'm looking forward to finding out :)
    Process.flag(:trap_exit, true)

    # assume setting up zeromq isn't fast so we don't want to do it in init
    # This uses an OTP "trick" where sending a message in init means it's the
    # first message the process will deal with when it starts so we can use it
    # to defer "booting". OTP waits until the init function is finished before
    # returning from the calling start_link so this allows the calling process
    # to continue while this server gets itself ready.
    IO.puts "ZeromqWorker pid #{inspect self}"
    send(self, :setup_zeromq)

    {:ok, %TimeMeOut.ZeromqWorker{owner: owner, params: params}}
  end

  def handle_info(:setup_zeromq, state) do
    IO.puts "Faking zeromq setup"
    # zero mq setup
    # this would be where you'd start the connection

    # then fake some zeromq messages
    # in reality these would come from the zeromq lib but using send_after here
    # demonstrates the idea without having to get into all that
    Process.send_after(self, {:data, :one, :web}, 20)
    Process.send_after(self, {:data, :two, :web}, 40)
    # web timeout will have fired for these
    Process.send_after(self, {:data, :three, :db}, 300)
    Process.send_after(self, {:data, :four, :db}, 900)
    # worker timeout will have fired for this
    Process.send_after(self, {:data, :five, :never_sent}, 1100)
    {:noreply, state}
  end

  # This just forwards the zeromq message to the owner process
  def handle_info(data, state) do
    IO.puts "ZeromqWorker sending #{inspect data}"
    send(state.owner, data)
    {:noreply, state}
  end

  # This isn't really necessary, it's just adding some debug output so we can
  # see that the process terminates before the fifth send_after call
  def terminate(_reason, _state) do
    IO.puts "ZeromqWorker terminating"
    :ok
  end
end
