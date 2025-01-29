defmodule PoopyLoopsWeb.PlaylistLive.FormComponent do
  use PoopyLoopsWeb, :live_component

  alias PoopyLoops.Playlists

  require Logger

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        for={@form}
        id="playlist-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Назва плейлиста" />
        <:actions>
          <button
            phx-disable-with="Saving..."
            class="flex bg-accent h-14 w-32 justify-center items-center rounded-xl border-2 border-accent hover:bg-transparent hover:border-accent active:bg-[rgba(11,61,42,0.08)]"
          >
            <svg
              width="26"
              height="22"
              viewBox="0 0 26 22"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                d="M2 9.28669C4.41986 11.9747 7.67265 14.6956 9.82211 17.4444C16.3 11.3333 16.8245 9.8741 24 4"
                stroke="#0B3D2A"
                stroke-width="3"
                stroke-linecap="round"
                stroke-linejoin="round"
              />
            </svg>
          </button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{playlist: playlist} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Playlists.change_playlist(playlist))
     end)}
  end

  @impl true
  def handle_event("validate", %{"playlist" => playlist_params}, socket) do
    changeset = Playlists.change_playlist(socket.assigns.playlist, playlist_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"playlist" => playlist_params}, socket) do
    save_playlist(socket, socket.assigns.action, playlist_params)
  end

  defp save_playlist(socket, :edit, playlist_params) do
    case Playlists.update_playlist(socket.assigns.playlist, playlist_params) do
      {:ok, playlist} ->
        notify_parent({:saved, playlist})

        {:noreply,
         socket
         |> put_flash(:info, "Playlist updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_playlist(socket, :new, playlist_params) do
    user_id = socket.assigns.playlist.user_id
    playlist_params = Map.put(playlist_params, "user_id", user_id)

    case Playlists.create_playlist(playlist_params) do
      {:ok, playlist} ->
        notify_parent({:saved, playlist})

        {:noreply,
         socket
         |> put_flash(:info, "Playlist created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.error("Failed to create playlist: #{inspect(changeset.errors)}")
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
