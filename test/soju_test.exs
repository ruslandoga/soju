defmodule SojuTest do
  use ExUnit.Case
  doctest Soju

  test "greets the world" do
    assert Soju.hello() == :world
  end
end
