defmodule PoopyLoopsWeb.PlaylistLive.Show do
  use PoopyLoopsWeb, :live_view

  alias PoopyLoops.Playlists
  alias PoopyLoops.PlaylistTracks
  alias PoopyLoops.Playlists.PlaylistTrack

  @impl true
  def mount(%{"id" => playlist_id}, _session, socket) do
    if connected?(socket) do
      # Unsubscribe first to ensure we don't have duplicate subscriptions
      Phoenix.PubSub.unsubscribe(PoopyLoops.PubSub, "playlist:#{playlist_id}")
      Phoenix.PubSub.unsubscribe(PoopyLoops.PubSub, PlaylistTracks.like_topic())

      Phoenix.PubSub.subscribe(PoopyLoops.PubSub, "playlist:#{playlist_id}")
      Phoenix.PubSub.subscribe(PoopyLoops.PubSub, PlaylistTracks.like_topic())
    end

    playlist = Playlists.get_playlist!(playlist_id)
    current_user = socket.assigns.current_user
    tracks = PlaylistTracks.list_tracks(playlist.id, current_user.id)

    {:ok,
     socket
     |> stream(:tracks, tracks)
     |> assign(
       playlist: playlist,
       current_user: socket.assigns[:current_user]
     )}
  end

  @impl true
  def handle_info({:track_added, track}, socket) do
    {:noreply, stream_insert(socket, :tracks, track, at: 0)}
  end

  @impl true
  def handle_info({:track_like_updated, %{track_id: track_id, like: like}}, socket) do
    updated_tracks = update_like_in_tracks(socket.assigns.tracks, track_id, like)
    {:noreply, assign(socket, tracks: updated_tracks)}
  end

  @impl true
  def handle_info({:track_like_removed, %{track_id: track_id, like: like}}, socket) do
    updated_tracks = remove_like_in_tracks(socket.assigns.tracks, track_id, like)
    {:noreply, assign(socket, tracks: updated_tracks)}
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

      {:error, :duplicate_track_in_playlist} ->
        {:noreply, put_flash(socket, :error, "This track is already in the playlist")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to add track: #{reason}")}
    end
  end

  @impl true
  def handle_event("delete_track", %{"track_id" => track_id}, socket) do
    case PlaylistTracks.delete(track_id) do
      {:ok, deleted_track} ->
        {:noreply, stream_delete(socket, :tracks, deleted_track)}

      {:error, :track_not_found} ->
        {:noreply, put_flash(socket, :error, "Track not found")}
    end
  end

  @impl true
  def handle_event("copy_url", %{"url" => url}, socket) do
    {:noreply,
     socket
     |> push_event("copy_to_clipboard", %{value: url})}
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

  defp update_like_in_tracks(tracks, track_id, like) do
    Enum.map(tracks, fn track ->
      if track.id == track_id do
        if like do
          %{track | likes: track.likes + 1}
        else
          %{track | dislikes: track.dislikes + 1}
        end
      else
        track
      end
    end)
  end

  defp remove_like_in_tracks(tracks, track_id, like) do
    Enum.map(tracks, fn track ->
      if track.id == track_id do
        if like do
          %{track | likes: track.likes - 1}
        else
          %{track | dislikes: track.dislikes - 1}
        end
      else
        track
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
