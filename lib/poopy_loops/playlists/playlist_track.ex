defmodule PoopyLoops.Playlists.PlaylistTrack do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.ULID

  @youtube_regex ~r/(?:https:\/\/www\.youtube\.com\/watch\?v=|https:\/\/youtu\.be\/)([a-zA-Z0-9_-]+)/

  def youtube_regex, do: @youtube_regex

  @primary_key {:id, ULID, autogenerate: true}
  @foreign_key_type Ecto.ULID
  schema "playlist_tracks" do
    field :url, :string
    belongs_to :playlist, PoopyLoops.Playlists.Playlist
    belongs_to :user, PoopyLoops.Accounts.User
    timestamps(type: :utc_datetime)

    has_many :playlist_track_likes, PoopyLoops.Playlists.TrackLike,
      foreign_key: :playlist_track_id

    field :likes, :integer, virtual: true
    field :dislikes, :integer, virtual: true
    field :track_liked, :boolean, virtual: true
    field :track_disliked, :boolean, virtual: true
  end

  @doc false
  def changeset(playlist_track, attrs) do
    playlist_track
    |> cast(attrs, [:url, :playlist_id, :user_id])
    |> validate_required([:url, :playlist_id, :user_id])
    |> validate_format(:url, @youtube_regex, message: "Must be a valid YouTube URL")
    |> assoc_constraint(:user)
    |> unique_constraint([:playlist_id, :url], name: :unique_track_in_playlist_idx)
  end
end
