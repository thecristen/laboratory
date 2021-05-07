defmodule Laboratory.Router do
  require EEx

  use Plug.Router

  plug Plug.Static, at: "/", from: :laboratory, only: ~w(css js)

  plug :match
  plug :dispatch

  get "/" do
    path = if conn.request_path == "/", do: "", else: conn.request_path

    conn
    |> put_resp_content_type("text/html")
    # |> send_resp(200, template(features(conn), path))
    |> resp(200, template(features(conn), path))
    |> send_resp
  end

  post "/disable/:id" do
    conn |> delete_resp_cookie(id) |> redirect_back
  end

  post "/enable/:id" do
    opts = Application.get_env(:laboratory, :cookie, [])
    conn |> put_resp_cookie(id, "true", opts) |> redirect_back
  end

  match _ do
    send_resp(conn, 404, "")
  end

  EEx.function_from_file :def, :template, "lib/laboratory/index.eex", [:features, :path]

  defp features(conn) do
    features = Application.get_env(:laboratory, :features)
    conn = fetch_cookies(conn)
    Enum.map features, fn ({id, name, description}) ->
      %Feature{
        id: id,
        name: name,
        description: description,
        enabled: conn.cookies[to_string(id)] == "true"
      }
    end
  end

  defp redirect_back(conn) do
    [referer] = get_req_header(conn, "referer")
    conn
    |> put_resp_header("location", referer)
    |> send_resp(conn.status || 302, "You are being redirected")
  end
end
