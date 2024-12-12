defmodule PoopyLoops.Playlists.PlaylistTrack do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.ULID

  @youtube_regex ~r/https:\/\/(?:www\.)?youtube\.com\/watch\?v=([a-zA-Z0-9_-]+)/

  def youtube_regex, do: @youtube_regex


  @primary_key {:id, ULID, autogenerate: true}
  @foreign_key_type Ecto.ULID
  schema "playlist_tracks" do
    field :added_at, :naive_datetime
    field :url, :string
    belongs_to :playlist, PoopyLoops.Playlists.Playlist
    belongs_to :user, PoopyLoops.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(playlist_track, attrs) do
    playlist_track
    |> cast(attrs, [:url, :added_at, :playlist_id, :user_id])
    |> validate_required([:url, :added_at, :playlist_id, :user_id])
    |> validate_format(:url, @youtube_regex, message: "Must be a valid YouTube URL")
    |> put_change(:added_at, NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
    |> assoc_constraint(:user)
  end
end
