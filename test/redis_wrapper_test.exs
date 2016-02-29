defmodule Plug.Session.RedisWrapperTest do
  use ExUnit.Case, async: true
  alias Plug.Session.RedisWrapper

  @opts %{ttl: 60, refresh_ttl_on_read: true}
  @data %{a: "value"}
  @key  "key"

  test "marsha/unmarshal" do 
    marshaled = RedisWrapper.marshal(@data)
    assert @data != marshaled
    unmarshaled = RedisWrapper.unmarshal(marshaled)
    assert @data == unmarshaled
  end

  test "key not found" do
    assert :not_found == RedisWrapper.get("nonexisting_key", @opts)
  end

  test "add & remove key/value" do
    assert :ok == RedisWrapper.set(@key, @data, @opts)
    assert {:ok, @data} == RedisWrapper.get(@key, @opts)

    assert :ok == RedisWrapper.del(@key, @opts)
    assert :not_found == RedisWrapper.get(@key, @opts)
  end
end
