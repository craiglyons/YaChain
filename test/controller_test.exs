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

  test "adds a new gensis block" do
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

  test "adds a post-gensis block" do
    proof1 = 100
    proof2 = 200
    previous_hash1 = "prevhash1"
    previous_hash2 = "prevhash2"

    Controller.new_block(:blocks_agent, :transactions_agent, proof1, previous_hash1)
    Controller.new_block(:blocks_agent, :transactions_agent, proof2, previous_hash2)

    agent_blocks = CurrentBlocks.all(:blocks_agent) |> nullify_timestamps()
    assert agent_blocks == [
      %Block{
        index: 0,
        transactions: [],
        proof: proof1,
        previous_hash: previous_hash1
      },
      %Block{
        index: 1,
        transactions: [],
        proof: proof2,
        previous_hash: previous_hash2
      },
    ]
  end

  defp nullify_timestamps(blocks) do
    Enum.map(blocks, fn block ->
      %{block | timestamp: nil}
    end)
  end
end
