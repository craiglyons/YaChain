defmodule Yachain.CurrentBlocks do
  use Agent

  @name __MODULE__

  @doc """
  Starts a new list of blocks.
  """
  def start_link(_opts) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  @doc """
  Gets all blocks in the list w/ identity function
  """
  def all(name \\ @name) do
    Agent.get(name, &(&1))
  end

  @doc """
  Gets the last block in the list.
  """
  def last(name \\ @name) do
    Agent.get(name, &List.last(&1))
  end

  @doc """
  Pushes the value `value` on the end of the list.
  """
  def push(name \\ @name, value) do
    Agent.update(name, &Kernel.++(&1, [value]))
  end

  @doc """
  Replaces the current list with `list`
  """
  def replace(name \\ @name, list) do
    Agent.update(name, fn current -> list end)
  end

end
