defmodule PlugHeadersBouncerTest do
  use ExUnit.Case, async: true
  use Plug.Test

  test "required header" do
    connection = conn(:get, "/") |> put_req_header("header", "value")
    response = TestAppRequire.call(connection, [])

    assert response.status == 200
  end

  test "required header missing" do
    connection = conn(:get, "/")
    response = TestAppRequire.call(connection, [])

    assert response.status == 400
  end

  test "required header missing error module" do
    connection = conn(:get, "/")
    response = TestAppRequireModule.call(connection, [])

    assert response.status == 400
    assert response.resp_body == "Missing header header"
  end

  test "required header missing error invalid module" do
    connection = conn(:get, "/")
    response = TestAppRequireBadModule.call(connection, [])

    assert response.status == 400
    assert response.resp_body == ""
  end

  test "required header missing error map" do
    connection = conn(:get, "/")
    response = TestAppRequireMap.call(connection, [])

    assert response.status == 400
    assert content_type(response) == "application/json; charset=utf-8"
    assert response.resp_body == Poison.encode!(%{header: "header", message: "Missing header"})
  end

  test "retrieve header" do
    connection = conn(:get, "/") |> put_req_header("header", "value")
    response = TestAppRetrieve.call(connection, [])

    assert response.status == 200
    assert response.assigns[:header] == "value"
  end

  test "match header value" do
    connection = conn(:get, "/") |> put_req_header("header", "value")
    response = TestAppMatch.call(connection, [])

    assert response.status == 200
  end

  test "match header value wrong" do
    connection = conn(:get, "/") |> put_req_header("header", "wrong")
    response = TestAppMatch.call(connection, [])

    assert response.status == 400
  end

  test "match header value module error" do
    connection = conn(:get, "/") |> put_req_header("header", "wrong")
    response = TestAppMatchModule.call(connection, [])

    assert response.status == 400
    assert response.resp_body == "Header header has the wrong value"
  end

  test "match header value invalid module error" do
    connection = conn(:get, "/") |> put_req_header("header", "wrong")
    response = TestAppMatchBadModule.call(connection, [])

    assert response.status == 400
    assert response.resp_body == ""
  end

  test "match header value map error" do
    connection = conn(:get, "/") |> put_req_header("header", "wrong")
    response = TestAppMatchMap.call(connection, [])

    assert response.status == 400
    assert content_type(response) == "application/json; charset=utf-8"
    assert response.resp_body == Poison.encode!(%{header: "header", message: "Not the expected value"})
  end

  test "contains header value" do
    connection = conn(:get, "/") |> put_req_header("header", "value")
    response = TestAppContains.call(connection, [])

    assert response.status == 200
  end

  test "does not contains header value" do
    connection = conn(:get, "/") |> put_req_header("header", "wrong")
    response = TestAppContains.call(connection, [])

    assert response.status == 400
  end

  test "contains header value module error" do
    connection = conn(:get, "/") |> put_req_header("header", "wrong")
    response = TestAppContainsModule.call(connection, [])

    assert response.status == 400
    assert response.resp_body == "Header header does not contains the expected value"
  end

  test "contains header value invalid module error" do
    connection = conn(:get, "/") |> put_req_header("header", "wrong")
    response = TestAppContainsBadModule.call(connection, [])

    assert response.status == 400
    assert response.resp_body == ""
  end

  test "contains header value map error" do
    connection = conn(:get, "/") |> put_req_header("header", "wrong")
    response = TestAppContainsMap.call(connection, [])

    assert response.status == 400
    assert content_type(response) == "application/json; charset=utf-8"
    assert response.resp_body == Poison.encode!(%{header: "header", message: "Does not contains the expected value"})
  end

  test "all params" do
    connection = conn(:get, "/") |> put_req_header("header", "value")
    response = TestAppAll.call(connection, [])

    assert response.status == 200
    assert response.resp_body == "Header value: value"
  end

  defp content_type(response) do
    case get_resp_header(response, "content-type") do
      [val | _] -> val
      _ -> nil
    end
  end
end
