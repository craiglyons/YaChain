defmodule Yachain.CurrentTransactions do
  use Agent

  @name __MODULE__

  @doc """
  Starts a new list of transactions.
  """
  def start_link(_opts) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  @doc """
  Gets all transactions in the list w/ identity function
  """
  def all(name \\ @name) do
    Agent.get(name, & &1)
  end

  @doc """
  Gets the last transaction in the list.
  """
  def last(name \\ @name) do
    Agent.get(name, &List.last(&1))
  end

  @doc """
  Pushes `value` on the end of the list.
  """
  def push(name \\ @name, value) do
    Agent.update(name, &Kernel.++(&1, [value]))
  end

  @doc """
  Clears all transactions from the list.
  """
  def clear(name \\ @name) do
    Agent.update(name, fn current -> [] end)
  end
end
