defmodule NotesWeb.NoteController do
  use NotesWeb, :controller

  alias Notes.Accounts
  alias Notes.Accounts.Note

  action_fallback NotesWeb.FallbackController

  def index(conn, _params) do
    notes = Accounts.list_notes()
    render(conn, "index.json", notes: notes)
  end

  def create(%{assigns: %{user_id: user_id}} = conn, %{"note" => %{"content" => content}}) do
    note_params = %{user_id: user_id, content: content}

    with {:ok, %Note{} = note} <- Accounts.create_note(note_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.user_note_path(conn, :show, user_id, note))
      |> render("show.json", note: note)
    end
  end

  def show(conn, %{"id" => id}) do
    note = Accounts.get_note_owned_by_user(get_user_id(conn), id)
    render(conn, "show.json", note: note)
  end

  def update(conn, %{"id" => id, "note" => note_params}) do
    note = Accounts.get_note_owned_by_user(get_user_id(conn), id)

    with {:ok, %Note{} = note} <- Accounts.update_note(note, note_params) do
      render(conn, "show.json", note: note)
    end
  end

  def delete(conn, %{"id" => id}) do
    note = Accounts.get_note_owned_by_user(get_user_id(conn), id)

    with {:ok, %Note{}} <- Accounts.delete_note(note) do
      send_resp(conn, :no_content, "")
    end
  end

  defp get_user_id(%{assigns: %{user_id: user_id}}), do: user_id
end
