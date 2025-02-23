defmodule PoopyLoopsWeb.GoogleAuthController do
  use PoopyLoopsWeb, :controller

  alias Assent.{Config, Strategy.Google}
  alias PoopyLoops.Accounts

  def request(conn, _params) do
    get_config()
    |> Config.put(:user_return_to, get_session(conn, :user_return_to))
    |> Google.authorize_url()
    |> case do
      {:ok, %{url: url, session_params: session_params}} ->
        # Session params (used for OAuth 2.0 and OIDC strategies) will be
        # retrieved when user returns for the callback phase
        conn = put_session(conn, :session_params, session_params)

        # Redirect end-user to Google to authorize access to their account
        conn
        |> put_resp_header("location", url)
        |> send_resp(302, "")

      {:error, error} ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(
          500,
          "Something went wrong generating the request authorization url: #{inspect(error)}"
        )
    end
  end

  def callback(conn, params) do
    # The session params (used for OAuth 2.0 and OIDC strategies) stored in the
    # request phase will be used in the callback phase
    session_params = get_session(conn, :session_params)

    get_config()
    # Session params should be added to the config so the strategy can use them
    |> Config.put(:session_params, session_params)
    |> Google.callback(params)
    |> case do
      {:ok, %{user: user, token: token}} ->
        # Authorization succesful
        IO.inspect({user, token}, label: "user and token")

        user_record = Accounts.get_user_by_email_or_register(user)
        IO.inspect(user, label: "user and token")

        conn
        |> PoopyLoopsWeb.UserAuth.log_in_user(user_record)

      {:error, error} ->
        # Authorizaiton failed
        IO.inspect(error, label: "error")

        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(500, inspect(error, pretty: true))
    end
  end

  defp get_config do
    [
      client_id: System.fetch_env!("GOOGLE_CLIENT_ID"),
      client_secret: System.fetch_env!("GOOGLE_CLIENT_SECRET"),
      redirect_uri: System.fetch_env!("GOOGLE_OAUTH_REDIRECT_URL")
    ]
  end
end
