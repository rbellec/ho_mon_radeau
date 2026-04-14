defmodule HoMonRadeauWeb.Api.CUFController do
  use HoMonRadeauWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias HoMonRadeau.CUF

  tags(["CUF"])

  operation(:index,
    summary: "List all CUF declarations",
    parameters: [
      status: [
        in: :query,
        type: :string,
        required: false,
        description: "validated, pending, or all"
      ]
    ],
    responses: [ok: {"CUF declarations", "application/json", %OpenApiSpex.Schema{type: :object}}]
  )

  def index(conn, params) do
    filter_status = Map.get(params, "status")
    declarations = CUF.list_all_declarations(filter_status: filter_status)
    json(conn, %{data: Enum.map(declarations, &serialize_declaration/1)})
  end

  operation(:validate,
    summary: "Validate a CUF declaration",
    parameters: [id: [in: :path, type: :integer, required: true]],
    responses: [
      ok: {"Validated declaration", "application/json", %OpenApiSpex.Schema{type: :object}}
    ]
  )

  def validate(conn, %{"id" => id}) do
    declaration = CUF.get_declaration!(id)

    case CUF.validate_declaration(declaration, conn.assigns.current_user) do
      {:ok, declaration} -> json(conn, %{data: serialize_declaration(declaration)})
      {:error, changeset} -> json_error(conn, changeset)
    end
  end

  operation(:settings,
    summary: "Get CUF settings",
    responses: [ok: {"Settings", "application/json", %OpenApiSpex.Schema{type: :object}}]
  )

  def settings(conn, _params) do
    settings = CUF.get_settings()

    json(conn, %{
      data: %{
        unit_price: settings.unit_price,
        total_limit: settings.total_limit
      }
    })
  end

  operation(:update_settings,
    summary: "Update CUF settings",
    responses: [ok: {"Updated settings", "application/json", %OpenApiSpex.Schema{type: :object}}]
  )

  def update_settings(conn, params) do
    case CUF.update_settings(params) do
      {:ok, settings} ->
        json(conn, %{data: %{unit_price: settings.unit_price, total_limit: settings.total_limit}})

      {:error, changeset} ->
        json_error(conn, changeset)
    end
  end

  defp serialize_declaration(declaration) do
    base = %{
      id: declaration.id,
      status: declaration.status,
      participant_count: declaration.participant_count,
      inserted_at: declaration.inserted_at
    }

    raft_info =
      case declaration do
        %{crew: %{raft: %{name: name, id: id}}} -> %{raft_id: id, raft_name: name}
        _ -> %{}
      end

    Map.merge(base, raft_info)
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
