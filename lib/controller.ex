defmodule Yachain.Controller do
  alias Yachain.Block
  alias Yachain.BlockTransaction
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

  def new_transaction(
        blocks_agent \\ CurrentBlocks,
        transactions_agent \\ CurrentTransactions,
        sender,
        recipient,
        amount) do

    CurrentTransactions.push(
      transactions_agent,
      %BlockTransaction{
        sender: sender,
        recipient: recipient,
        amount: amount,
      })
    CurrentBlocks.last(blocks_agent) |> Map.fetch!(:index)
  end

  def proof_of_work(last_proof, proof \\ 0) do
    case valid_proof(last_proof, proof) do
      true ->
        proof
      false ->
        proof_of_work(last_proof, proof + 1)
    end
  end

  defp valid_proof(last_proof, proof) do
    guess = Integer.to_string(last_proof) <> Integer.to_string(proof)
    guess_hash = :crypto.hash(:sha256, guess) |> Base.encode16
    String.slice(guess_hash, 0, 4) |> valid_proof()
  end

  defp valid_proof("0000") do
    true
  end

  defp valid_proof(_nonzero) do
    false
  end

  def hash(block) do
    # Naiively rely on struct key sorting
    json_block = Poison.encode!(block)
    :crypto.hash(:sha256, json_block) |> Base.encode16
  end

  def mine(blocks_agent, transactions_agent) do
    last_block = CurrentBlocks.last(blocks_agent)
    last_proof = last_block.proof
    proof = proof_of_work(last_proof)

    new_transaction(
      blocks_agent,
      transactions_agent,
      "0",
      Node.self,
      1)

    previous_hash = hash(last_block)
    block = new_block(blocks_agent, transactions_agent, proof, previous_hash)
  end
end
