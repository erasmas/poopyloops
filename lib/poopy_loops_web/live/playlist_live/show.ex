defmodule PoopyLoopsWeb.PlaylistLive.Show do
  use PoopyLoopsWeb, :live_view

  alias PoopyLoops.Playlists
  alias PoopyLoops.PlaylistTracks
  alias PoopyLoops.Playlists.PlaylistTrack

  @impl true
  def mount(%{"id" => playlist_id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(PoopyLoops.PubSub, "playlist:#{playlist_id}")
      Phoenix.PubSub.subscribe(PoopyLoops.PubSub, PlaylistTracks.like_topic())
    end

    playlist = Playlists.get_playlist!(playlist_id)

    tracks_by_id =
      PlaylistTracks.list_tracks(playlist.id) |> Enum.into(%{}, fn track -> {track.id, track} end)

    {:ok,
     assign(socket,
       playlist: playlist,
       current_user: socket.assigns[:current_user],
       tracks_by_id: tracks_by_id
     )}
  end

  @impl true
  def handle_info({:track_added, track}, socket) do
    {:noreply,
     assign(socket, tracks_by_id: Map.put(socket.assigns.tracks_by_id, track.id, track))}
  end

  @impl true
  def handle_info({:track_like_updated, %{track_id: track_id, like: like}}, socket) do
    updated_tracks = update_like_in_tracks(socket.assigns.tracks_by_id, track_id, like)
    {:noreply, assign(socket, tracks_by_id: updated_tracks)}
  end

  @impl true
  def handle_info({:track_like_removed, %{track_id: track_id, like: like}}, socket) do
    updated_tracks = remove_like_in_tracks(socket.assigns.tracks_by_id, track_id, like)
    {:noreply, assign(socket, tracks_by_id: updated_tracks)}
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

    case PlaylistTracks.add_track(playlist_id, youtube_link, current_user) do
      {:ok, _track} ->
        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to add track: #{reason}")}
    end
  end

  @impl true
  def handle_event("toggle_like", %{"track_id" => track_id, "like" => like}, socket) do
    user_id = socket.assigns.current_user.id
    like = String.to_existing_atom(like)

    case PlaylistTracks.toggle_like(user_id, track_id, like) do
      {:ok, _} ->
        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to toggle like.")}
    end
  end

  defp update_like_in_tracks(tracks_by_id, track_id, like) do
    Map.update!(tracks_by_id, track_id, fn track ->
      if like do
        %{track | likes: track.likes + 1}
      else
        %{track | dislikes: track.dislikes + 1}
      end
    end)
  end

  defp remove_like_in_tracks(tracks_by_id, track_id, like) do
    Map.update!(tracks_by_id, track_id, fn track ->
      if like do
        %{track | likes: track.likes - 1}
      else
        %{track | dislikes: track.dislikes - 1}
      end
    end)
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
