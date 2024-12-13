defmodule PoopyLoops.Playlists.TrackLike do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.ULID

  @primary_key {:id, ULID, autogenerate: true}
  @foreign_key_type Ecto.ULID
  schema "playlist_track_likes" do
    field :like, :boolean
    belongs_to :playlist_track, PoopyLoops.Playlists.PlaylistTrack
    belongs_to :user, PoopyLoops.Accounts.User
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(track_like, attrs) do
    track_like
    |> cast(attrs, [:playlist_track_id, :user_id, :like])
    |> validate_required([:playlist_track_id, :user_id, :like])
    |> assoc_constraint(:user)
    |> assoc_constraint(:playlist_track)
    |> unique_constraint([:playlist_track_id, :user_id, :like])
  end
end
