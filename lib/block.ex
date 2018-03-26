defmodule Yachain.Block do
  alias __MODULE__

  defstruct(
    index: nil,
    timestamp: nil,
    transactions: [],
    proof: nil,
    previous_hash: nil
  )
end
