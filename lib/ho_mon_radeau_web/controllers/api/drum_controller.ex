defmodule HoMonRadeauWeb.Api.DrumController do
  use HoMonRadeauWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias HoMonRadeau.Drums

  tags(["Drums"])

  operation(:index,
    summary: "List all drum declarations",
    responses: [ok: {"Drum declarations", "application/json", %OpenApiSpex.Schema{type: :object}}]
  )

  def index(conn, _params) do
    declarations = Drums.list_all_declarations()
    json(conn, %{data: Enum.map(declarations, &serialize_declaration/1)})
  end

  operation(:validate_payment,
    summary: "Mark a drum declaration as paid",
    parameters: [id: [in: :path, type: :integer, required: true]],
    responses: [
      ok: {"Validated declaration", "application/json", %OpenApiSpex.Schema{type: :object}}
    ]
  )

  def validate_payment(conn, %{"id" => id}) do
    declaration = Drums.get_declaration!(id)

    case Drums.validate_payment(declaration, conn.assigns.current_user.id) do
      {:ok, declaration} -> json(conn, %{data: serialize_declaration(declaration)})
      {:error, changeset} -> json_error(conn, changeset)
    end
  end

  operation(:settings,
    summary: "Get drum settings",
    responses: [ok: {"Settings", "application/json", %OpenApiSpex.Schema{type: :object}}]
  )

  def settings(conn, _params) do
    settings = Drums.get_settings()

    json(conn, %{
      data: %{
        forfait_price: settings.forfait_price,
        rib_iban: settings.rib_iban,
        rib_bic: settings.rib_bic
      }
    })
  end

  operation(:update_settings,
    summary: "Update drum settings",
    responses: [ok: {"Updated settings", "application/json", %OpenApiSpex.Schema{type: :object}}]
  )

  def update_settings(conn, params) do
    case Drums.update_settings(params) do
      {:ok, settings} ->
        json(conn, %{
          data: %{
            forfait_price: settings.forfait_price,
            rib_iban: settings.rib_iban
          }
        })

      {:error, changeset} ->
        json_error(conn, changeset)
    end
  end

  defp serialize_declaration(declaration) do
    %{
      id: declaration.id,
      declared: declaration.declared,
      mode: declaration.mode,
      total_quantity: declaration.total_quantity,
      status: declaration.status,
      total_amount: declaration.total_amount,
      inserted_at: declaration.inserted_at
    }
    |> maybe_merge_raft(declaration)
  end

  defp maybe_merge_raft(map, %{crew: %{raft: %{name: name, id: id}}}),
    do: Map.merge(map, %{raft_id: id, raft_name: name})

  defp maybe_merge_raft(map, _), do: map

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
