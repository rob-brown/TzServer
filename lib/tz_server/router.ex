defmodule TzServer.Router do
  use Plug.Router
  use Plug.ErrorHandler
  require Logger

  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  ## Routes

  get "/dst_info/all" do
    with {:ok, new_conn} <-
           conn
           |> put_resp_content_type("application/json")
           |> send_chunked(:ok)
           |> chunk("{") do
      TzServer.all_zone_names()
      |> Stream.map(&[?", &1, ?", ?:, Poison.encode_to_iodata!(TzServer.dst_info(&1))])
      |> Stream.intersperse(",")
      |> Enum.into(new_conn)
      |> chunk("}")
      |> elem(1)
    else
      _ ->
        send_error(conn, :internal_server_error, "Internal Error")
    end
  end

  get "/dst_info/version" do
    %{"version" => TzServer.version()} |> Poison.encode_to_iodata!() |> send_json(conn)
  end

  get "/dst_info/periods/:count/all" do
    with count = String.to_integer(count),
         {:ok, new_conn} <-
           conn
           |> put_resp_content_type("application/json")
           |> send_chunked(:ok)
           |> chunk("{") do
      TzServer.all_zone_names()
      |> Stream.map(&[?", &1, ?", ?:, Poison.encode_to_iodata!(TzServer.periods(&1, count))])
      |> Stream.intersperse(",")
      |> Enum.into(new_conn)
      |> chunk("}")
      |> elem(1)
    else
      _ ->
        send_error(conn, :internal_server_error, "Internal Error")
    end
  end

  get "/dst_info/periods/:count/:name" do
    periods(name, String.to_integer(count), conn)
  end

  get "/dst_info/periods/:count/:region/:location" do
    [region, location] |> Enum.join("/") |> periods(String.to_integer(count), conn)
  end

  get "/dst_info/periods/:count/:region/:country/:location" do
    [region, country, location] |> Enum.join("/") |> periods(String.to_integer(count), conn)
  end

  get "/dst_info/:name" do
    dst_info(name, conn)
  end

  get "/dst_info/:region/:location" do
    [region, location] |> Enum.join("/") |> dst_info(conn)
  end

  get "/dst_info/:region/:country/:location" do
    [region, country, location] |> Enum.join("/") |> dst_info(conn)
  end

  match _ do
    Logger.warn("Path not found: #{inspect(conn.request_path)}")
    send_error(conn, :not_found, "Not Found")
  end

  ## Helpers

  defp dst_info(name, conn) do
    with :ok <- TzServer.validate_timezone(name),
         info = TzServer.dst_info(name),
         json = Poison.encode_to_iodata!(%{name => info}) do
      send_json(json, conn)
    else
      {:error, :unknown_timezone} ->
        send_error(conn, :not_found, "Not Found")
    end
  end

  defp periods(name, count, conn) do
    with :ok <- TzServer.validate_timezone(name),
         info = TzServer.periods(name, count),
         json = Poison.encode_to_iodata!(%{name => info}) do
      send_json(json, conn)
    else
      {:error, :unknown_timezone} ->
        send_error(conn, :not_found, "Not Found")
    end
  end

  defp send_json(json, conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(:ok, json)
  end

  defp send_error(conn, status, msg) do
    with json = Poison.encode_to_iodata!(%{error: msg}) do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(status, json)
    end
  end

  def handle_errors(
        conn,
        error = %{kind: _, reason: %{message: msg, plug_status: status}, stack: _}
      ) do
    Logger.error("Request error: #{inspect(error)}")
    send_error(conn, status, msg)
  end

  def handle_errors(conn, error) do
    Logger.error("Request error: #{inspect(error)}")
    send_error(conn, conn.status, "Internal server error")
  end
end
