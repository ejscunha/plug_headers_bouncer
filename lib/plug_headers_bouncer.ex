defmodule PlugHeadersBouncer do
  import Plug.Conn

  @moduledoc ~S"""
  An Elixir Plug for retriving, required and matching a given list of headers.
  """

  @type conn :: Plug.Conn
  @type ops :: keyword()

  @doc ~S"""
  Initialises the plug given a keyword list.
  """
  @spec init(ops) :: ops
  def init(ops), do: ops

  @doc ~S"""
  Assigns the headers values to the Plug.Conn construct, checks if a required list of headers are
  present in the request, and checks if a list of headers have the expected values.

  ## Arguments

  `conn` - the Plug.Conn connection struct
  `ops` - a keyword list broken down into retrieve, required and match headers

  ## Options

  `:required` - a list of tuples with the name of the headers that are required to be
  present in the connection. It must have the following format `{<header>, <ops>}` where
  * the `header` binary is the name of the header required.
  * the `ops` parameter is either a module name that implements the `PlugHeadersBouncer.Error`
  behaviour or is a map with the optional keys `status`, `message` and `format`. `status` is the
  http status code to be returned, `message` is the response payload to be sent and `format` is to
  set the response content type (can be `:text` or `:json`).

  `:retrieve` - a keyword list of key and header pairs.
  Assigns the `header` value to the `key` in the connection struct.
  Each pair has the format `[<key>: <header>]` where
  * the `key` atom is the connection key to assign the value of the header.
  * the `header` binary is the header name from where the value will be extracted.

  `:match` - a list of tuples where each tuple has the format `{<header>, <value>}` or
  `{<header>, <value>, <ops>}`.
  Validates that an header has the expected value.
  * the `header` binary is the header name that we want to check the value.
  * the `value` binary is the value that we expect that the header has.
  * the `ops` parameter is either a module name that implements the `PlugHeadersBouncer.Error`
  behaviour or is a map with the optional keys `status`, `message` and `format`. `status` is the
  http status code to be returned, `message` is the response payload to be sent and `format` is to
  set the response content type (can be `:text` or `:json`).

  `:contains` - a list of tuples where each tuple has the format `{<header>, <value>}` or
  `{<header>, <value>, <ops>}`.
  Validates that and header contains a given value.
  * the `header` binary is the header name that we want to check the value.
  * the `value` binary is the value that we expect that is contained in the header value.
  * the `ops` parameter is either a module name that implements the `PlugHeadersBouncer.Error`
  behaviour or is a map with the optional keys `status`, `message` and `format`. `status` is the
  http status code to be returned, `message` is the response payload to be sent and `format` is to
  set the response content type (can be `:text` or `:json`).
  """
  @spec call(conn, ops) :: conn
  def call(conn, ops) do
    required = Keyword.get(ops, :required, [])
    retrieve = Keyword.get(ops, :retrieve, [])
    match = Keyword.get(ops, :match, [])
    contains = Keyword.get(ops, :contains, [])

    with %{halted: false} = req_conn <- required_headers(conn, required),
         %{halted: false} = ret_conn <- retrieve_headers(req_conn, retrieve),
         %{halted: false} = mat_conn <- match_headers(ret_conn, match),
         %{halted: false} = con_conn <- contains_headers(mat_conn, contains) do
      con_conn
    else
      conn -> conn
      _ -> conn
    end
  end

  defp required_headers(conn, required) when is_list(required) do
    Enum.reduce_while(required, conn, &check_required_header(&2, &1))
  end

  defp check_required_header(conn, {header_name, ops} = header) when is_tuple(header) do
    check_required_header(conn, header_name, ops)
  end
  defp check_required_header(conn, header, error_ops \\ nil) do
    value = get_header_value(conn, header)
    if is_nil(value) do
      {:halt, error_response(conn, header, error_ops)}
    else
      {:cont, conn}
    end
  end

  defp retrieve_headers(conn, retrieve) when is_list(retrieve) do
    Enum.reduce(retrieve, conn, &retrieve_headers(&2, &1))
  end
  defp retrieve_headers(conn, {key, header}) when is_atom(key) and is_binary(header) do
    value = get_header_value(conn, header)
    assign(conn, key, value)
  end

  defp match_headers(conn, match) when is_list(match) do
    Enum.reduce_while(match, conn, &match_headers(&2, &1))
  end
  defp match_headers(conn, {header, value}) when is_binary(header) do
    check_match_header(conn, header, value)
  end
  defp match_headers(conn, {header, value, mod}) when is_binary(header) and is_atom(mod) and not is_nil(mod) do
    check_match_header(conn, header, value, mod)
  end
  defp match_headers(conn, {header, value, ops}) when is_binary(header) and is_map(ops) do
    check_match_header(conn, header, value, ops)
  end

  defp check_match_header(conn, header, value, ops \\ nil) do
    header_value = get_header_value(conn, header)
    if value != header_value do
      {:halt, error_response(conn, header, ops)}
    else
      {:cont, conn}
    end
  end

  defp contains_headers(conn, contains) when is_list(contains) do
    Enum.reduce_while(contains, conn, &contains_headers(&2, &1))
  end
  defp contains_headers(conn, {header, value}) when is_binary(header) do
    check_contains_header(conn, header, value)
  end
  defp contains_headers(conn, {header, value, mod}) when is_binary(header) and is_atom(mod) and not is_nil(mod) do
    check_contains_header(conn, header, value, mod)
  end
  defp contains_headers(conn, {header, value, ops}) when is_binary(header) and is_map(ops) do
    check_contains_header(conn, header, value, ops)
  end

  defp check_contains_header(conn, header, value, ops \\ nil) do
    header_value = get_header_value(conn, header)
    if !is_nil(header_value) and String.contains?(header_value, value) do
      {:cont, conn}
    else
      {:halt, error_response(conn, header, ops)}
    end
  end

  defp get_header_value(conn, header) do
    case get_req_header(conn, header) do
      [value | _] -> value
      _ -> nil
    end
  end

  defp error_response(conn, header, mod) when is_atom(mod) and not is_nil(mod) do
    if Code.ensure_loaded?(mod) do
      mod.call(conn, header)
    else
      error_response(conn, header, nil)
    end
  end
  defp error_response(conn, _header, ops) when is_map(ops) do
    status = Map.get(ops, :status, 400)
    message = Map.get(ops, :message, "")
    format = Map.get(ops, :format, :text)

    conn
    |> put_resp_content_type(response_format(format))
    |> send_resp(status, format_message(message, format))
    |> halt()
  end
  defp error_response(conn, _header, _ops) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(400, "")
    |> halt()
  end

  defp response_format(:json), do: "application/json"
  defp response_format(_), do: "text/plain"

  defp format_message(message, :json), do: Poison.encode!(message)
  defp format_message(message, _), do: message
end
