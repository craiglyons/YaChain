defmodule Yachain do
  use Application
  require Logger
  @moduledoc """
  Documentation for Yachain.
  """

  def start(_type, _args) do
    IO.puts("*** starting ***")
    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Yachain.Controller, [], port: 8080),
      Yachain.CurrentTransactions
    ]

    Logger.info("Started application")

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
