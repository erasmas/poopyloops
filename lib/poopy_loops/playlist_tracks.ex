defmodule PoopyLoops.PlaylistTracks do

  import Ecto.Query

  alias PoopyLoops.Repo
  alias PoopyLoops.Playlists.PlaylistTrack

  def list_tracks(playlist_id) do
    Repo.all(from pt in PlaylistTrack, where: pt.playlist_id == ^playlist_id, preload: [:user])
  end

  def get_playlist_track!(id), do: Repo.get!(PlaylistTrack, id)

  def add_track(playlist_id, youtube_link, user_id) do
    %PlaylistTrack{}
    |> PlaylistTrack.changeset(%{
      playlist_id: playlist_id,
      url: youtube_link,
      user_id: user_id,
      added_at: NaiveDateTime.utc_now()
    })
    |> Repo.insert()
  end

  # def create_playlist_track(attrs \\ %{}) do
  #   %PlaylistTrack{}
  #   |> PlaylistTrack.changeset(attrs)
  #   |> Repo.insert()
  # end
  #
  # def update_playlist_track(%PlaylistTrack{} = playlist_track, attrs) do
  #   playlist_track
  #   |> PlaylistTrack.changeset(attrs)
  #   |> Repo.update()
  # end
  #
  # def delete_playlist_track(%PlaylistTrack{} = playlist_track) do
  #   Repo.delete(playlist_track)
  # end
  #
  # def change_playlist_track(%PlaylistTrack{} = playlist_track, attrs \\ %{}) do
  #   PlaylistTrack.changeset(playlist_track, attrs)
  # end
  # 
end
