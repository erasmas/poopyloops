defmodule PoopyLoops.Repo.Migrations.CreatePlaylistTracks do
  use Ecto.Migration

  def change do
    create table(:playlist_tracks) do
      add :url, :string
      add :playlist_id, references(:playlists, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:playlist_tracks, [:playlist_id])
    create index(:playlist_tracks, [:user_id])

    create unique_index(:playlist_tracks, [:playlist_id, :url],
             name: :unique_track_in_playlist_idx
           )
  end
end
