defmodule Plug.Session.RedisStore do
  @moduledoc """
  Stores the session in a Redis Table.

  ## Options

    * `:ttl` - Key Expiration (required)
    * `:refresh_ttl_on_read` - Reset TTL everytime the key is read (required)

  """

  require Logger

  alias Plug.Session.RedisWrapper

  @behaviour Plug.Session.Store

  def init(opts) do
    %{ 
      ttl: Keyword.fetch!(opts, :ttl),
      refresh_ttl_on_read: Keyword.fetch!(opts, :refresh_ttl_on_read)
    }
  end

  def get(_conn, sid, opts) do
    Logger.debug "[Plug.Session.RedisStore.get] sid: #{sid} opts: #{inspect opts}"
    
    case RedisWrapper.get(sid, opts) do 
      {:ok, data} -> {sid, data}
      :not_found  -> {nil, %{}}
    end
  end

  def put(conn, nil, data, opts) do
    put(conn, generate_sid, data, opts)
  end

  def put(_conn, sid, data, opts) do
    Logger.debug "[Plug.Session.RedisStore.put] sid: #{sid} opts: #{inspect opts} data: #{inspect data}"
    case RedisWrapper.set(sid, data, opts) do
      :ok -> sid
      _   -> nil
    end
  end

  def delete(_conn, sid, opts) do
    Logger.debug "[Plug.Session.RedisStore.delete] sid: #{sid} opts: #{inspect opts}"
    RedisWrapper.del(sid, opts)
    :ok
  end

  defp generate_sid(), do: :crypto.strong_rand_bytes(96) |> Base.encode64
end


