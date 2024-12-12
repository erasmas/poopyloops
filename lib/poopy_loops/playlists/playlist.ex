defmodule PoopyLoops.Playlists.Playlist do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.ULID, autogenerate: true}
  @foreign_key_type Ecto.ULID
  schema "playlists" do
    field :name, :string
    belongs_to :user, PoopyLoops.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(playlist, attrs) do
    playlist
    |> cast(attrs, [:name, :user_id])
    |> validate_required([:name, :user_id])
    |> assoc_constraint(:user)
  end
end
