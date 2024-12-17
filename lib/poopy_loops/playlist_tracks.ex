defmodule PoopyLoops.PlaylistTracks do
  import Ecto.Query

  alias PoopyLoops.Repo
  alias PoopyLoops.Playlists.PlaylistTrack
  alias PoopyLoops.Playlists.TrackLike

  @like_topic "playlist_track_likes_topic"

  def like_topic(), do: @like_topic

  def list_tracks(playlist_id, user_id) do
    Repo.all(
      from pt in PlaylistTrack,
        where: pt.playlist_id == ^playlist_id,
        left_join: tl in assoc(pt, :playlist_track_likes),
        left_join: user_like in PoopyLoops.Playlists.TrackLike,
        on: user_like.playlist_track_id == pt.id and user_like.user_id == ^user_id,
        group_by: pt.id,
        select_merge: %{
          likes: filter(count(tl.id), tl.like == true),
          dislikes: filter(count(tl.id), tl.like == false),
          track_liked:
            coalesce(
              fragment("MAX(CASE WHEN ? THEN 1 ELSE 0 END) = 1", user_like.like == true),
              false
            ),
          track_disliked:
            coalesce(
              fragment("MAX(CASE WHEN ? THEN 1 ELSE 0 END) = 1", user_like.like == false),
              false
            )
        },
        order_by: [desc: count(tl.id, :distinct)],
        preload: [:user]
    )
  end

  def get_playlist_track!(id), do: Repo.get!(PlaylistTrack, id)

  def add_track(playlist_id, youtube_link, added_by_user) do
    saved_track =
      %PlaylistTrack{}
      |> PlaylistTrack.changeset(%{
        playlist_id: playlist_id,
        url: youtube_link,
        user_id: added_by_user.id
      })
      |> Repo.insert()

    case saved_track do
      {:ok, track} ->
        # Broadcast the new track to the playlist topic
        Phoenix.PubSub.broadcast(
          PoopyLoops.PubSub,
          "playlist:#{playlist_id}",
          {:track_added, %{track | user: added_by_user, likes: 0, dislikes: 0}}
        )

        {:ok, track}

      {:error, %Ecto.Changeset{} = changeset} ->
        if Keyword.has_key?(changeset.errors, :playlist_id) do
          {:error, :duplicate_track_in_playlist}
        else
          {:error, inspect(changeset.errors)}
        end
    end
  end

  def toggle_like(user_id, track_id, like) do
    Repo.transaction(fn ->
      # Fetch existing like/dislike
      existing = Repo.get_by(TrackLike, user_id: user_id, playlist_track_id: track_id)

      case existing do
        # If an existing like/dislike exists, remove it first
        %TrackLike{like: _} ->
          Repo.delete!(existing)

          broadcast_like_event(:track_like_removed, %{
            track_id: track_id,
            user_id: user_id,
            like: existing.like
          })

          # If the new like/dislike is different, insert it
          if existing.like != like do
            changeset =
              %TrackLike{}
              |> TrackLike.changeset(%{user_id: user_id, playlist_track_id: track_id, like: like})

            case Repo.insert(changeset) do
              {:ok, new_like} ->
                broadcast_like_event(:track_like_updated, %{
                  track_id: new_like.playlist_track_id,
                  user_id: new_like.user_id,
                  like: new_like.like
                })

                {:ok, :updated}

              {:error, changeset} ->
                {:error, changeset}
            end
          else
            {:ok, :removed}
          end

        # If no existing like/dislike, insert a new one
        nil ->
          changeset =
            %TrackLike{}
            |> TrackLike.changeset(%{user_id: user_id, playlist_track_id: track_id, like: like})

          case Repo.insert(changeset) do
            {:ok, new_like} ->
              broadcast_like_event(:track_like_updated, %{
                track_id: new_like.playlist_track_id,
                user_id: new_like.user_id,
                like: new_like.like
              })

              {:ok, :updated}

            {:error, changeset} ->
              {:error, changeset}
          end
      end
    end)
  end

  defp broadcast_like_event(event_type, payload) do
    Phoenix.PubSub.broadcast(PoopyLoops.PubSub, @like_topic, {event_type, payload})
  end
end
