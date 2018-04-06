defmodule Yachain.Controller do
  alias Yachain.Block
  alias Yachain.BlockTransaction
  alias Yachain.CurrentTransactions
  alias Yachain.CurrentBlocks

  def get_chain(blocks_agent \\ CurrentBlocks) do
    CurrentBlocks.all(blocks_agent)
  end

  def new_transaction(
        blocks_agent \\ CurrentBlocks,
        transactions_agent \\ CurrentTransactions,
        sender,
        recipient,
        amount
      ) do
    CurrentTransactions.push(transactions_agent, %BlockTransaction{
      sender: sender,
      recipient: recipient,
      amount: amount
    })

    CurrentBlocks.last(blocks_agent) |> Map.fetch!(:index)
  end

  def new_block(blocks_agent, transactions_agent, proof, previous_hash) do
    current_blocks = CurrentBlocks.all(blocks_agent)
    current_transactions = CurrentTransactions.all(transactions_agent)

    block = %Block{
      index: current_blocks |> length,
      timestamp: DateTime.utc_now(),
      transactions: current_transactions,
      proof: proof,
      previous_hash: previous_hash
    }

    CurrentTransactions.clear(transactions_agent)
    CurrentBlocks.push(blocks_agent, block)
    block
  end

  def new_block(
        blocks_agent \\ CurrentBlocks,
        transactions_agent \\ CurrentTransactions,
        the_proof
      ) do
    previous_hash = CurrentBlocks.last(blocks_agent) |> hash()
    new_block(blocks_agent, transactions_agent, the_proof, previous_hash)
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
    guess_hash = :crypto.hash(:sha256, guess) |> Base.encode16()
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
    :crypto.hash(:sha256, json_block) |> Base.encode16()
  end

  def mine(
        blocks_agent \\ CurrentBlocks,
        transactions_agent \\ CurrentTransactions
      ) do
    last_block = CurrentBlocks.last(blocks_agent)
    last_proof = last_block.proof
    proof = proof_of_work(last_proof)

    new_transaction(blocks_agent, transactions_agent, "0", Node.self(), 1)

    previous_hash = hash(last_block)
    new_block(blocks_agent, transactions_agent, proof, previous_hash)
  end

  def valid_chain?(chain) do
    valid_chain?(chain, 0)
  end

  def valid_chain?(chain, current_index) do
    chain_length = length(chain)
    previous_block = Enum.at(chain, current_index)
    current_block = Enum.at(chain, current_index + 1)

    cond do
      current_index == chain_length - 1 ->
        true

      invalid_block?(previous_block, current_block) ->
        false

      true ->
        valid_chain?(chain, current_index + 1)
    end
  end

  def insert_genesis_block(
        blocks_agent \\ CurrentBlocks,
        transactions_agent \\ CurrentTransactions
      ) do
    proof1 = 100
    previous_hash1 = "n/a"
    new_block(blocks_agent, transactions_agent, proof1, previous_hash1)
  end

  defp invalid_block?(previous_block, current_block) do
    current_block.previous_hash != hash(previous_block) ||
      !valid_proof(previous_block.proof, current_block.proof)
  end

  def resolve_conflicts() do
    longest_chain = Node.list()
    |> Enum.map(fn(node) -> :rpc.call(node, Yachain.Controller, :get_chain, []) end)
    |> longest_chain()

    replace_current_chain? = (longest_chain |> length()) > (get_chain() |> length())
    case replace_current_chain? do
      true ->
        IO.puts("*** Consensus loss, replacing current chain ***")
        CurrentBlocks.replace(longest_chain)
        longest_chain
      _ ->
        IO.puts("*** Consensus win, keeping current chain ***")
        get_chain
    end
  end

  def longest_chain(chains) do
    chains
    |> Enum.filter(&valid_chain?/1)
    |> Enum.sort(&(length(&1) > length(&2)))
    |> Enum.at(0)
  end

  def magic_button() do
    Node.connect(:"bar@localhost")
    insert_genesis_block()
    mine()
    new_transaction("Sender1", "Recipient1", 123.00)
    new_transaction("Sender2", "Recipient2", 234.00)
    new_transaction("Sender3", "Recipient3", 345.00)
    mine()
  end
end
