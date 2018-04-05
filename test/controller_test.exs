defmodule ControllerTest do
  use ExUnit.Case, async: true
  alias Yachain.Controller
  alias Yachain.BlockTransaction
  alias Yachain.Block
  alias Yachain.CurrentBlocks
  alias Yachain.CurrentTransactions

  setup do
    transaction1 = %BlockTransaction{
      sender: "sender1",
      recipient: "recipient1",
      amount: "123.00"
    }

    transaction2 = %BlockTransaction{
      sender: "sender2",
      recipient: "recipient2",
      amount: "234.00"
    }

    block1 = %Block{
      index: 0,
      timestamp: nil,
      transactions: [],
      proof: 324984774000,
      previous_hash: "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824",
    }

    %{
      block1: block1,
      transaction1: transaction1,
      transaction2: transaction2
    }

    Agent.start_link(fn -> [] end, name: :transactions_agent)
    Agent.start_link(fn -> [] end, name: :blocks_agent)
    :ok
  end

  test "new_block adds a new gensis block" do
    proof1 = 100
    previous_hash1 = "1"

    Controller.new_block(:blocks_agent, :transactions_agent, proof1, previous_hash1)
    agent_blocks = CurrentBlocks.all(:blocks_agent) |> nullify_timestamps()
    assert agent_blocks == [
      %Block{
        index: 0,
        transactions: [],
        proof: proof1,
        previous_hash: previous_hash1
      }]
  end

  test "new_block adds current transactions to the block & clears them" do
    proof1 = 100
    previous_hash1 = "prevhash1"

    transaction1 = %BlockTransaction{
      sender: "sender1",
      recipient: "recipient1",
      amount: 123,
    }
    transaction2 = %BlockTransaction{
      sender: "sender1",
      recipient: "recipient1",
      amount: 234,
    }

    CurrentTransactions.push(:transactions_agent, transaction1)
    CurrentTransactions.push(:transactions_agent, transaction2)
    assert (CurrentTransactions.all(:transactions_agent) |> length) == 2

    Controller.new_block(:blocks_agent, :transactions_agent, proof1, previous_hash1)

    agent_blocks = CurrentBlocks.all(:blocks_agent) |> nullify_timestamps()
    assert agent_blocks == [
      %Block{
        index: 0,
        transactions: [transaction1, transaction2],
        proof: proof1,
        previous_hash: previous_hash1
      }
    ]

    assert (CurrentTransactions.all(:transactions_agent) |> length) == 0
  end

  test "new_block generates previous_hash if not provided" do
    block0 = Controller.insert_genesis_block(:blocks_agent, :transactions_agent)
    # Push the transactions block
    proof2 = 200
    transaction1 = %BlockTransaction{
      sender: "sender1",
      recipient: "recipient1",
      amount: 123,
    }

    transaction2 = %BlockTransaction{
      sender: "sender1",
      recipient: "recipient1",
      amount: 234,
    }
    CurrentTransactions.push(:transactions_agent, transaction1)
    CurrentTransactions.push(:transactions_agent, transaction2)
    Controller.new_block(:blocks_agent, :transactions_agent, proof2)

    # Assertions
    expected_previous_hash1 = Controller.hash(block0)
    agent_blocks = CurrentBlocks.all(:blocks_agent) |> nullify_timestamps()

    assert agent_blocks == [
      %Block{
        index: 0,
        transactions: [],
        proof: 100,
        previous_hash: "n/a"
      },
      %Block{
        index: 1,
        transactions: [transaction1, transaction2],
        proof: proof2,
        previous_hash: expected_previous_hash1
      }
    ]

    latest_block = CurrentBlocks.last(:blocks_agent)
    assert latest_block.previous_hash == expected_previous_hash1
  end


  test "new_transaction pushes 2 new transactions & returns the indices" do
    # Genesis block is required to get block index in new_transaction function
    Controller.insert_genesis_block(:blocks_agent, :transactions_agent)

    sender1 = "sender1"
    sender2 = "sender2"
    recipient1 = "recipient1"
    recipient2 = "recipient2"
    amount1 = "amount1"
    amount2 = "amount2"

    result1 = Controller.new_transaction(
      :blocks_agent,
      :transactions_agent,
      sender1,
      recipient1,
      amount1
    )
    assert result1 == 0

    result2 = Controller.new_transaction(
      :blocks_agent,
      :transactions_agent,
      sender2,
      recipient2,
      amount2
    )
    assert result2 == 0

    all = CurrentTransactions.all(:transactions_agent)
    assert all == [
      %BlockTransaction{ sender: sender1, recipient: recipient1, amount: amount1 },
      %BlockTransaction{ sender: sender2, recipient: recipient2, amount: amount2 },
    ]
  end


  test "calculates accurate proofs of work" do
    proof = Controller.proof_of_work(1)
    assert proof == 72608
    proof = Controller.proof_of_work(12345)
    assert proof == 18083
    proof = Controller.proof_of_work(12346)
    assert proof == 2594
  end

  test "mining creates a new transaction & log" do
    block0 = Controller.insert_genesis_block(:blocks_agent, :transactions_agent)
    expected_previous_hash1 = Controller.hash(block0)

    Controller.mine(:blocks_agent, :transactions_agent)

    expected_blocks = [
      block0,
      %Block{
        index: 1,
        previous_hash: expected_previous_hash1,
        proof: 35293,
        transactions: [
          %BlockTransaction{
            amount: 1,
            recipient: :nonode@nohost,
            sender: "0"
          },
        ],
      },
    ] |> nullify_timestamps()

    actual_blocks = CurrentBlocks.all(:blocks_agent) |> nullify_timestamps()
    assert expected_blocks == actual_blocks
  end

  test "valid_chain? reports true for an valid chain" do
    block0 = Controller.insert_genesis_block(:blocks_agent, :transactions_agent)

    block1 = next_block(block0)
    block2 = next_block(block1)
    block3 = next_block(block2)
    block4 = next_block(block3)

    chain = [block0, block1, block2, block3, block4]
    assert Controller.valid_chain?(chain) == true
  end

  test "valid_chain? reports false for a chain with a conflicting hash" do
    block0 = Controller.insert_genesis_block(:blocks_agent, :transactions_agent)

    block1 = next_block(block0)
    block2 = next_block(block1)
    block3 = next_block(block2)
    block3 = %{block3 | previous_hash: "not a real hash"}
    block4 = next_block(block3)

    chain = [block0, block1, block2, block3, block4]
    assert Controller.valid_chain?(chain) == false
  end

  test "valid_chain? reports false for a chain with a conflicting proof" do
    block0 = Controller.insert_genesis_block(:blocks_agent, :transactions_agent)

    block1 = next_block(block0)
    block2 = next_block(block1)
    block3 = next_block(block2)
    block4 = next_block(block3)
    block4 = %{block4 | proof: 12345}

    chain = [block0, block1, block2, block3, block4]
    assert Controller.valid_chain?(chain) == false
  end

  test "longest_chain returns the longest chain in a list" do
    block0 = Controller.insert_genesis_block(:blocks_agent, :transactions_agent)

    block1 = next_block(block0)
    block2 = next_block(block1)
    block3 = next_block(block2)

    chain1 = [ block1, block2 ]
    chain2 = [ block1, block2, block3 ]
    chain3 = [ block1 ]
    assert Controller.longest_chain([chain1, chain2, chain3]) == chain2
  end

  defp next_block(previous_block) do
    proof = Controller.proof_of_work(previous_block.proof)
    previous_hash1 = Controller.hash(previous_block)
    Controller.new_block(:blocks_agent, :transactions_agent, proof, previous_hash1)
  end

  defp nullify_timestamps(blocks) do
    Enum.map(blocks, fn block ->
      %{block | timestamp: nil}
    end)
  end
end
