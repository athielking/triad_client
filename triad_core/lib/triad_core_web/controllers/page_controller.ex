defmodule TriadCoreWeb.PageController do
  use TriadCoreWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
