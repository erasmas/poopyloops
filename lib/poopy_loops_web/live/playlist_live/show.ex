defmodule PoopyLoopsWeb.PlaylistLive.Show do
  use PoopyLoopsWeb, :live_view

  alias PoopyLoops.Playlists
  alias PoopyLoops.PlaylistTracks
  alias PoopyLoops.Playlists.PlaylistTrack

  @impl true
  def mount(params, _session, socket) do
    playlist = Playlists.get_playlist!(params["id"])
    tracks = PlaylistTracks.list_tracks(playlist.id)

    {:ok, assign(socket, playlist: playlist, tracks: tracks, current_user: socket.assigns[:current_user])}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:playlist, Playlists.get_playlist!(id))}
  end

  @impl true
  def handle_event("add_track", %{"youtube_link" => youtube_link}, socket) do
    playlist_id = socket.assigns.playlist.id
    current_user = socket.assigns.current_user

    IO.inspect(socket.assigns, label: "Socket assigns")

    case PlaylistTracks.add_track(playlist_id, youtube_link, current_user.id) do
      {:ok, _track} ->
        updated_tracks = PlaylistTracks.list_tracks(playlist_id)
        {:noreply, assign(socket, tracks: updated_tracks)}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to add track: #{reason}")}
    end
  end

  def get_video_id(url) do
    case Regex.run(PlaylistTrack.youtube_regex(), url) do
      [_, video_id] -> video_id
      _ -> nil
    end
  end

  defp page_title(:show), do: "Show Playlist"
  defp page_title(:edit), do: "Edit Playlist"
end
