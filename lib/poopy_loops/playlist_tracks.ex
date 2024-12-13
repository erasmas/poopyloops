defmodule PoopyLoops.PlaylistTracks do
  import Ecto.Query

  alias PoopyLoops.Repo
  alias PoopyLoops.Playlists.PlaylistTrack
  alias PoopyLoops.Playlists.TrackLike

  def list_tracks(playlist_id) do
    Repo.all(
      from pt in PlaylistTrack,
        where: pt.playlist_id == ^playlist_id,
        left_join: tl in assoc(pt, :playlist_track_likes),
        group_by: pt.id,
        select_merge: %{
          likes: filter(count(tl.id), tl.like == true),
          dislikes: filter(count(tl.id), tl.like == false)
        },
        preload: [:user]
    )
  end

  def get_playlist_track!(id), do: Repo.get!(PlaylistTrack, id)

  def add_track(playlist_id, youtube_link, user_id) do
    %PlaylistTrack{}
    |> PlaylistTrack.changeset(%{
      playlist_id: playlist_id,
      url: youtube_link,
      user_id: user_id
    })
    |> Repo.insert()
  end

  def toggle_like(user_id, playlist_track_id, like) do
    Repo.transaction(fn ->
      # Fetch the existing like/dislike for this user and track
      existing = Repo.get_by(TrackLike, playlist_track_id: playlist_track_id, user_id: user_id)

      cond do
        # If the same like/dislike exists, delete it (toggle off)
        existing && existing.like == like ->
          Repo.delete!(existing)

        # If there's an opposite reaction, update it
        existing ->
          existing
          |> TrackLike.changeset(%{like: like})
          |> Repo.update!()

        # If no existing interaction, insert a new one
        true ->
          %TrackLike{}
          |> TrackLike.changeset(%{
            playlist_track_id: playlist_track_id,
            user_id: user_id,
            like: like
          })
          |> Repo.insert!()
      end
    end)
  end
end
