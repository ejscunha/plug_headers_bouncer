defmodule PlugHeadersBouncer.Error do
  @type conn :: Plug.Conn
  @type header :: String.t

  @callback call(conn, header) :: conn
end
