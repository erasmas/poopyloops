defmodule PoopyLoopsWeb.LoginLive do
  use PoopyLoopsWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="bg-accent has-brand-pattern w-full">
      <div class="flex flex-col gap-16 h-screen justify-center items-center">
        <img src="/images/poopy-logo-main.svg" class="w-3/4" />
        <.link
          href={~p"/auth/google"}
          class="phx-submit-loading:opacity-75 rounded-full bg-auth hover:bg-authhover"
        >
          <img src="/images/google-icon.svg" class="w-32 h-32" />
        </.link>
      </div>
    </div>
    """
  end
end

# <.error :if={@error_message}>{@error_message}</.error>
