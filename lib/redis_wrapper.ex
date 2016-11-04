defmodule Plug.Session.RedisWrapper do
  @moduledoc """
  Wrapper around redis connection
  """

  alias RedisPoolex, as: Redis
  
  def get(key, _opts = %{refresh_ttl_on_read: true, ttl: ttl}) do 
    Redis.query(["MULTI"])
    Redis.query(["GET", key])
    Redis.query(["EXPIRE", key, ttl])
    case Redis.query(["EXEC"]) do 
      [:undefined | _] -> :not_found
      [v | _]          -> {:ok, unmarshal(v)}
    end
  end

  def get(key, _opts = %{refresh_ttl_on_read: false}) do 
    case Redis.query(["GET", key]) do
      :undefined -> :not_found
      v          -> {:ok, unmarshal(v)}
    end
  end

  def set(key, data, _opts = %{ttl: ttl}) do 
    Redis.query(["MULTI"])
    Redis.query(["SET", key, marshal(data)])
    Redis.query(["EXPIRE", key, ttl])
    case Redis.query(["EXEC"]) do 
      ["OK", "1"] -> :ok
      _error      -> :error
    end
  end

  def del(key, _opts) do 
    case Redis.query(["DEL", key]) do
      "1"    -> :ok
      "0"    -> :not_found
      _error -> :error
    end
  end

  def marshal(data), do: :erlang.term_to_binary(data) |> Base.encode64 

  def unmarshal(data), do: Base.decode64(data) |> elem(1) |> :erlang.binary_to_term
end

