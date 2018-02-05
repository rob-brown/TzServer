defmodule TzServerTest do
  use ExUnit.Case
  doctest TzServer

  test "greets the world" do
    assert TzServer.hello() == :world
  end
end
