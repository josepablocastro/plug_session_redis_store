defmodule Plug.Session.RedisStoreTest do
  use ExUnit.Case, async: true

  use Plug.Test

  defmodule AppRouter do
    use Plug.Router

    plug :match
    plug :dispatch

    get "/hello" do
      conn
      |> Plug.Conn.fetch_session
      |> Plug.Conn.put_session("foo", "bar")
      |> Plug.Conn.put_session("foo2", "bar")
      |> Plug.Conn.delete_session("foo2")
      |> send_resp(200, "world")
    end

  end

  @opts AppRouter.init([])
  
  def with_session(conn) do
    session_opts = Plug.Session.init(
      key: "_session_redis_store_key",
      store: Plug.Session.RedisStore,
      signing_salt: "SBRvpcSC",
      ttl: 900,
      refresh_ttl_on_read: true
    )
    conn
    |> Map.put(:secret_key_base, String.duplicate("abcdefgh", 8))
    |> Plug.Session.call(session_opts)
    |> Plug.Conn.fetch_session()
    |> Plug.Conn.fetch_query_params()
  end

  def get_cookie_size conn do
    conn.resp_headers 
    |> Enum.filter( fn {"set-cookie", _ } -> true; _ -> false end )
    |> Enum.at( 0 )
    |> elem( 1 )
    |> String.length
  end

  #test "the truth" do
    #assert 1 + 1 == 2
    #end

  test "memcached-saved sessions shall have always the same cookie size" do
    # Create a test connection
    conn = with_session conn(:get, "/hello")
    
    # set "foo" key in get "/hello" (defined in router
    conn = AppRouter.call(conn, @opts)
    assert conn.private.plug_session["foo"] == "bar"
    assert conn.private.plug_session["foo2"] == nil
    #IO.inspect cookie_size_one_key = get_cookie_size conn

    # set another key
    #conn = Plug.Conn.put_session( conn, "bang", String.duplicate("qwertzuiop", 20 ) )
    #assert conn.private.plug_session["bang"] == String.duplicate("qwertzuiop", 20 )
    #cookie_size_two_keys = get_cookie_size conn
    #assert cookie_size_one_key == cookie_size_two_keys

    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "world"
  end
end
