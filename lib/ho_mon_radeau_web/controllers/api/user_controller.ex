defmodule HoMonRadeauWeb.Api.UserController do
  use HoMonRadeauWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias HoMonRadeau.Accounts

  tags(["Users"])

  operation(:index,
    summary: "List all confirmed users",
    responses: [ok: {"User list", "application/json", %OpenApiSpex.Schema{type: :object}}]
  )

  def index(conn, _params) do
    users = Accounts.list_all_users()
    json(conn, %{data: Enum.map(users, &serialize_user/1)})
  end

  operation(:search,
    summary: "Search users by nickname or email",
    parameters: [q: [in: :query, type: :string, required: true]],
    responses: [ok: {"Search results", "application/json", %OpenApiSpex.Schema{type: :object}}]
  )

  def search(conn, %{"q" => query}) do
    users = Accounts.search_users(query)
    json(conn, %{data: Enum.map(users, &serialize_user/1)})
  end

  operation(:show,
    summary: "Get a single user",
    parameters: [id: [in: :path, type: :integer, required: true]],
    responses: [ok: {"User", "application/json", %OpenApiSpex.Schema{type: :object}}]
  )

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    json(conn, %{data: serialize_user(user)})
  end

  operation(:validate,
    summary: "Validate a user (welcome team approval)",
    parameters: [id: [in: :path, type: :integer, required: true]],
    responses: [ok: {"Validated user", "application/json", %OpenApiSpex.Schema{type: :object}}]
  )

  def validate(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)

    case Accounts.validate_user(user) do
      {:ok, user} -> json(conn, %{data: serialize_user(user)})
      {:error, changeset} -> json_error(conn, changeset)
    end
  end

  operation(:invalidate,
    summary: "Revoke user validation",
    parameters: [id: [in: :path, type: :integer, required: true]],
    responses: [ok: {"Invalidated user", "application/json", %OpenApiSpex.Schema{type: :object}}]
  )

  def invalidate(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)

    case Accounts.invalidate_user(user) do
      {:ok, user} -> json(conn, %{data: serialize_user(user)})
      {:error, changeset} -> json_error(conn, changeset)
    end
  end

  defp serialize_user(user) do
    %{
      id: user.id,
      email: user.email,
      nickname: user.nickname,
      first_name: user.first_name,
      last_name: user.last_name,
      validated: user.validated,
      is_admin: user.is_admin,
      display_name: Accounts.display_name(user),
      inserted_at: user.inserted_at
    }
  end

  defp json_error(conn, changeset) do
    errors =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
          opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
        end)
      end)

    conn |> put_status(:unprocessable_entity) |> json(%{errors: errors})
  end
end
