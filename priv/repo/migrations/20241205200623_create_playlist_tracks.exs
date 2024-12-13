defmodule PoopyLoops.Repo.Migrations.CreatePlaylistTracks do
  use Ecto.Migration

  def change do
    create table(:playlist_tracks) do
      add :url, :string
      add :playlist_id, references(:playlists, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:playlist_tracks, [:playlist_id])
    create index(:playlist_tracks, [:user_id])
  end
end
