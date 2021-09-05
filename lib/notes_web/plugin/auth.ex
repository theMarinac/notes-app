defmodule NotesWeb.Plugin.Auth do
  import Plug.Conn
  import Phoenix.Controller

  @namespace "user-authorization"
  @max_age 30 * 24 * 60 * 60

  @doc """
  A function plug that ensures that `:user_id` value is present.

  ## Examples

      # in a router pipeline
      pipe_through [:api, :require_auth]

      # in a controller
      plug :require_auth when action in [:index, :create]
  """

  def require_auth(conn, _params) do
    conn
    |> get_token()
    |> verify_token()
    |> case do
      {:ok, user_id} ->
        conn
        |> assign(:user_id, user_id)

      {:error, _} ->
        conn
        |> put_status(:unauthorized)
        |> put_view(NotesWeb.ErrorView)
        |> render(:"401")
        |> halt()
    end
  end

  @doc """
  Generate a new token for a user id.

  ## Examples

      iex> NotesWeb.Plugin.Auth.generate_token(123)
      "xx.yy.zz"

  """
  def generate_token(user_id), do: Phoenix.Token.encrypt(NotesWeb.Endpoint, @namespace, user_id)

  @doc """
  Verify a user token.

  ## Examples

      iex> NotesWeb.Plugin.Auth.verify_token("good-token")
      {:ok, 1}

      iex> NotesWeb.Plugin.Auth.verify_token("bad-token")
      {:error, :invalid}

      iex> NotesWeb.Plugin.Auth.verify_token("old-token")
      {:error, :expired}

      iex> NotesWeb.Plugin.Auth.verify_token(nil)
      {:error, :missing}

  """
  @spec verify_token(nil | binary) :: {:error, :expired | :invalid | :missing} | {:ok, any}
  def verify_token(token),
    do: Phoenix.Token.decrypt(NotesWeb.Endpoint, @namespace, token, max_age: @max_age)

  @spec get_token(Plug.Conn.t()) :: nil | binary
  def get_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> token
      _ -> nil
    end
  end
end