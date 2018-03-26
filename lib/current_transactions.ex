defmodule Yachain.CurrentTransactions do
  use Agent

  @doc """
  Starts a new list of transactions.
  """
  def start_link(_opts) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  @doc """
  Gets all transactions in the list w/ identity function
  """
  def all() do
    Agent.get(__MODULE__, &(&1))
  end

  @doc """
  Gets the last transaction in the list.
  """
  def last() do
    Agent.get(__MODULE__, &List.last(&1))
  end

  @doc """
  Pushes the value `value` on the end of the list.
  """
  def push(value) do
    Agent.update(__MODULE__, &Kernel.++(&1, [value]))
  end

end