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
        blocks_agent,
        transactions_agent,
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

  def new_block(
        blocks_agent \\ CurrentBlocks,
        transactions_agent \\ CurrentTransactions,
        the_proof) do
    previous_hash = CurrentBlocks.last(blocks_agent) |> hash()
    new_block(blocks_agent, transactions_agent, the_proof, previous_hash)
  end

  def hash(block) do
    # Naiively rely on struct key sorting
    json_block = Poison.encode!(block)
    hashed = :crypto.hash(:sha256, "whatever") |> Base.encode16
  end

end
