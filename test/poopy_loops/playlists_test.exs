defmodule PoopyLoops.PlaylistsTest do
  use PoopyLoops.DataCase

  alias PoopyLoops.Playlists

  describe "playlists" do
    alias PoopyLoops.Playlists.Playlist

    import PoopyLoops.PlaylistsFixtures

    @invalid_attrs %{name: nil}

    test "list_playlists/0 returns all playlists" do
      playlist = playlist_fixture()
      assert Playlists.list_playlists() == [playlist]
    end

    test "get_playlist!/1 returns the playlist with given id" do
      playlist = playlist_fixture()
      assert Playlists.get_playlist!(playlist.id) == playlist
    end

    test "create_playlist/1 with valid data creates a playlist" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Playlist{} = playlist} = Playlists.create_playlist(valid_attrs)
      assert playlist.name == "some name"
    end

    test "create_playlist/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Playlists.create_playlist(@invalid_attrs)
    end

    test "update_playlist/2 with valid data updates the playlist" do
      playlist = playlist_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Playlist{} = playlist} = Playlists.update_playlist(playlist, update_attrs)
      assert playlist.name == "some updated name"
    end

    test "update_playlist/2 with invalid data returns error changeset" do
      playlist = playlist_fixture()
      assert {:error, %Ecto.Changeset{}} = Playlists.update_playlist(playlist, @invalid_attrs)
      assert playlist == Playlists.get_playlist!(playlist.id)
    end

    test "delete_playlist/1 deletes the playlist" do
      playlist = playlist_fixture()
      assert {:ok, %Playlist{}} = Playlists.delete_playlist(playlist)
      assert_raise Ecto.NoResultsError, fn -> Playlists.get_playlist!(playlist.id) end
    end

    test "change_playlist/1 returns a playlist changeset" do
      playlist = playlist_fixture()
      assert %Ecto.Changeset{} = Playlists.change_playlist(playlist)
    end
  end
end
