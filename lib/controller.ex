defmodule Yachain.Controller do
  alias Yachain.Block
  alias Yachain.CurrentTransactions
  alias Yachain.CurrentBlocks
  # import Plug.Conn

  # def init(options), do: options

  # def call(conn, _opts) do
  #   conn
  #   |> put_resp_content_type("text/plain")
  #   |> send_resp(200, "I'm a blockchain\n")
  # end
  def new_block(
        blocks_agent \\ CurrentBlocks,
        transactions_agent \\ CurrentTransactions,
        proof,
        previous_hash) do
    current_blocks = CurrentBlocks.all(blocks_agent)
    current_transactions = CurrentTransactions.all(transactions_agent)

    block = %Block{
      index: current_blocks |> Kernel.length,
      timestamp: DateTime.utc_now,
      transactions: current_transactions,
      proof: proof,
      previous_hash: previous_hash,
    }

    CurrentTransactions.clear(transactions_agent)
    CurrentBlocks.push(blocks_agent, block)
    block
  end

end
