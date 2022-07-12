defmodule SmTest do
  use ExUnit.Case
  doctest Sm

  test "greets the world" do
    assert Sm.hello() == :world
  end
end
