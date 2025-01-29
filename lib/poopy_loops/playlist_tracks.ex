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

  def delete(track_id) do
    case Repo.get(PlaylistTrack, track_id) do
      nil ->
        {:error, :track_not_found}

      track ->
        Repo.delete(track)
    end
  end

  def toggle_like(user_id, track_id, like) do
    Repo.transaction(fn ->
      {track, existing_like} =
        Repo.one(
          from pt in PlaylistTrack,
            where: pt.id == ^track_id,
            left_join: tl in assoc(pt, :playlist_track_likes),
            left_join: user_like in TrackLike,
            on: user_like.playlist_track_id == pt.id and user_like.user_id == ^user_id,
            group_by: [pt.id, user_like.id, user_like.like],
            select: {
              merge(pt, %{
                likes: filter(count(tl.id), tl.like == true),
                dislikes: filter(count(tl.id), tl.like == false)
              }),
              user_like
            },
            preload: [:user]
        )

      case existing_like do
        %TrackLike{} = like_record ->
          Repo.delete!(like_record)

          # Decrement the existing like/dislike
          track = update_track_counts(track, like_record.like, :decrement)
          broadcast_track(track, false, false)

          if like_record.like != like do
            case insert_like(track_id, user_id, like) do
              {:ok, _} ->
                track = update_track_counts(track, like, :increment)
                broadcast_track(track, like, !like)
                {:ok, :updated}

              error ->
                error
            end
          else
            {:ok, :removed}
          end

        nil ->
          case insert_like(track_id, user_id, like) do
            {:ok, _} ->
              track = update_track_counts(track, like, :increment)
              broadcast_track(track, like, !like)
              {:ok, :updated}

            error ->
              error
          end
      end
    end)
  end

  defp insert_like(track_id, user_id, like) do
    %TrackLike{}
    |> TrackLike.changeset(%{user_id: user_id, playlist_track_id: track_id, like: like})
    |> Repo.insert()
  end

  defp update_track_counts(track, like, operation) do
    case {like, operation} do
      {true, :increment} -> %{track | likes: track.likes + 1}
      {true, :decrement} -> %{track | likes: max(track.likes - 1, 0)}
      {false, :increment} -> %{track | dislikes: track.dislikes + 1}
      {false, :decrement} -> %{track | dislikes: max(track.dislikes - 1, 0)}
    end
  end

  defp broadcast_track(track, track_liked, track_disliked) do
    updated_track = %{track | track_liked: track_liked, track_disliked: track_disliked}

    Phoenix.PubSub.broadcast(
      PoopyLoops.PubSub,
      @like_topic,
      {:track_updated, updated_track}
    )
  end
end
