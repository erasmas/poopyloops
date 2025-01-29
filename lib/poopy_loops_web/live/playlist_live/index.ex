defmodule PoopyLoopsWeb.PlaylistLive.Index do
  use PoopyLoopsWeb, :live_view

  alias PoopyLoops.Playlists
  alias PoopyLoops.Playlists.Playlist

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id

    {:ok,
     socket
     |> stream(:playlists, Playlists.list_user_playlists(user_id))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Редагувати назву плейлиста")
    |> assign(:playlist, Playlists.get_playlist!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Cтворити новий плейлист")
    |> assign(:playlist, %Playlist{user_id: socket.assigns.current_user.id})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Playlists")
    |> assign(:playlist, nil)
  end

  @impl true
  def handle_info({PoopyLoopsWeb.PlaylistLive.FormComponent, {:saved, playlist}}, socket) do
    {:noreply, stream_insert(socket, :playlists, playlist)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    playlist = Playlists.get_playlist!(id)
    {:ok, _} = Playlists.delete_playlist(playlist)

    {:noreply, stream_delete(socket, :playlists, playlist)}
  end
end
