defmodule PoopyLoops.Repo.Migrations.AddTrackLikesTable do
  use Ecto.Migration

  def change do
    create table(:playlist_track_likes) do
      add :user_id, references(:users, on_delete: :nothing), null: false
      add :playlist_track_id, references(:playlist_tracks, on_delete: :nothing), null: false
      add :like, :boolean, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:playlist_track_likes, [:user_id, :playlist_track_id])
  end
end
