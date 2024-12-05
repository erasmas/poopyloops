defmodule PoopyLoopsWeb.PlaylistLive.FormComponent do
  use PoopyLoopsWeb, :live_component

  alias PoopyLoops.Playlists

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage playlist records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="playlist-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Playlist</.button>
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
    case Playlists.create_playlist(playlist_params) do
      {:ok, playlist} ->
        notify_parent({:saved, playlist})

        {:noreply,
         socket
         |> put_flash(:info, "Playlist created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
