defmodule YachainTest do
  use ExUnit.Case
  doctest Yachain

  test "greets the world" do
    assert Yachain.hello() == :world
  end
end
