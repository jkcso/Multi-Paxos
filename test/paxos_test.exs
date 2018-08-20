defmodule PaxosTest do
  use ExUnit.Case
  doctest Paxos

  test "greets the world" do
    assert Paxos.hello() == :world
  end
end
