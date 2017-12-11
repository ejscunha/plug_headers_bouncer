ExUnit.start()

defmodule AppMaker do
  defmacro __using__(options) do
    quote do
      use Plug.Router

      plug PlugHeadersBouncer, unquote(options)
      plug :match
      plug :dispatch
    end
  end
end

defmodule TestAppAll do
  use AppMaker, [required: ["header"], retrieve: [header: "header"], match: [{"header", "value"}], contains: [{"header", "val"}]]

  get "/" do
    send_resp(conn, 200, "Header value: #{conn.assigns[:header]}")
  end
end

defmodule TestAppRequire do
  use AppMaker, [required: ["header"]]

  get "/" do
    send_resp(conn, 200, "")
  end
end

defmodule TestAppRequireModule do
  use AppMaker, [required: [{"header", RequireError}]]

  get "/" do
    send_resp(conn, 200, "")
  end
end

defmodule TestAppRequireBadModule do
  use AppMaker, [required: [{"header", BadRequireError}]]

  get "/" do
    send_resp(conn, 200, "")
  end
end

defmodule TestAppRequireMap do
  use AppMaker, [required: [{"header", %{status: 400, message: %{header: "header", message: "Missing header"}, format: :json}}]]

  get "/" do
    send_resp(conn, 200, "")
  end
end

defmodule RequireError do
  import Plug.Conn

  @behaviour PlugHeadersBouncer.Error

  def call(conn, header) do
    conn
    |> send_resp(400, "Missing header #{header}")
    |> halt()
  end
end

defmodule TestAppRetrieve do
  use AppMaker, [retrieve: [header: "header"]]

  get "/" do
    send_resp(conn, 200, "#{conn.assigns[:header]}")
  end
end

defmodule TestAppMatch do
  use AppMaker, [match: [{"header", "value"}]]

  get "/" do
    send_resp(conn, 200, "")
  end
end

defmodule TestAppMatchModule do
  use AppMaker, [match: [{"header", "value", HeaderMatchError}]]

  get "/" do
    send_resp(conn, 200, "")
  end
end

defmodule TestAppMatchBadModule do
  use AppMaker, [match: [{"header", "value", BadHeaderMatchError}]]

  get "/" do
    send_resp(conn, 200, "")
  end
end

defmodule TestAppMatchMap do
  use AppMaker, [match: [{"header", "value", %{status: 400, message: %{header: "header", message: "Not the expected value"}, format: :json}}]]

  get "/" do
    send_resp(conn, 200, "")
  end
end

defmodule HeaderMatchError do
  import Plug.Conn

  @behaviour PlugHeadersBouncer.Error

  def call(conn, header) do
    conn
    |> send_resp(400, "Header #{header} has the wrong value")
    |> halt()
  end
end

defmodule TestAppContains do
  use AppMaker, [contains: [{"header", "val"}]]

  get "/" do
    send_resp(conn, 200, "")
  end
end

defmodule TestAppContainsModule do
  use AppMaker, [contains: [{"header", "val", ContainsError}]]

  get "/" do
    send_resp(conn, 200, "")
  end
end

defmodule TestAppContainsBadModule do
  use AppMaker, [contains: [{"header", "val", BadContainsError}]]

  get "/" do
    send_resp(conn, 200, "")
  end
end

defmodule TestAppContainsMap do
  use AppMaker, [contains: [{"header", "val", %{status: 400, message: %{header: "header", message: "Does not contains the expected value"}, format: :json}}]]

  get "/" do
    send_resp(conn, 200, "")
  end
end

defmodule ContainsError do
  import Plug.Conn

  @behaviour PlugHeadersBouncer.Error

  def call(conn, header) do
    conn
    |> send_resp(400, "Header #{header} does not contains the expected value")
    |> halt()
  end
end
