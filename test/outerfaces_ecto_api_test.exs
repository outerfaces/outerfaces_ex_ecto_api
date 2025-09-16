defmodule OuterfacesEctoApiTest do
  use ExUnit.Case
  doctest OuterfacesEctoApi

  test "greets the world" do
    assert OuterfacesEctoApi.hello() == :world
  end
end
