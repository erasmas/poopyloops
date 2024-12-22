defmodule PoopyLoopsWeb.RedirectController do
  use PoopyLoopsWeb, :controller

  def redirect_to_playlists(conn, _params) do
    redirect(conn, to: "/playlists")
  end
end
