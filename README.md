# 💩 PoopyLoops

[PoopyLoops](https://poopyloops.fyi) is a silly little web service to collaborate on music playlists and vote for the most liked songs.
Previously, I was using Excel spreadsheets for this, but it was dull and had a corporate smell.

This was built just for fun and to try out [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html).

PoopyLoops has the following features:

* Authentication using Google OAuth
* Updates to a playlist are broadcasted to clients using [Phoenix.PubSub](https://hexdocs.pm/phoenix_pubsub/2.1.3/Phoenix.PubSub.html)
* Playlist tracks are sorted based on reactions
* Playlists can be shared using a private link
* Impressive logo and design by [alexyzhuk](https://github.com/alexyzhuk)

## Development

To start your Phoenix server:

  * Run `docker-compose up`
  * Run `mix setup` to install and setup dependencies
  * Run `mix ecto.migrate` to apply DB migrations
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
