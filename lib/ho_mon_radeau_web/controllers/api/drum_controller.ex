defmodule HoMonRadeauWeb.Api.DrumController do
  use HoMonRadeauWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias HoMonRadeau.Drums

  tags(["Drums"])

  operation(:index,
    summary: "List all drum requests",
    parameters: [
      status: [in: :query, type: :string, required: false, description: "paid, pending, or all"]
    ],
    responses: [ok: {"Drum requests", "application/json", :map}]
  )

  def index(conn, params) do
    filter_status = Map.get(params, "status")
    requests = Drums.list_all_requests(filter_status: filter_status)
    json(conn, %{data: Enum.map(requests, &serialize_request/1)})
  end

  operation(:validate_payment,
    summary: "Mark a drum request as paid",
    parameters: [id: [in: :path, type: :integer, required: true]],
    responses: [ok: {"Validated request", "application/json", :map}]
  )

  def validate_payment(conn, %{"id" => id}) do
    request = Drums.get_request!(id)

    case Drums.validate_payment(request, conn.assigns.current_user) do
      {:ok, request} -> json(conn, %{data: serialize_request(request)})
      {:error, changeset} -> json_error(conn, changeset)
    end
  end

  operation(:settings,
    summary: "Get drum settings",
    responses: [ok: {"Settings", "application/json", :map}]
  )

  def settings(conn, _params) do
    settings = Drums.get_settings()

    json(conn, %{
      data: %{
        unit_price: settings.unit_price,
        rib: settings.rib
      }
    })
  end

  operation(:update_settings,
    summary: "Update drum settings",
    responses: [ok: {"Updated settings", "application/json", :map}]
  )

  def update_settings(conn, params) do
    case Drums.update_settings(params) do
      {:ok, settings} ->
        json(conn, %{data: %{unit_price: settings.unit_price, rib: settings.rib}})

      {:error, changeset} ->
        json_error(conn, changeset)
    end
  end

  defp serialize_request(request) do
    base = %{
      id: request.id,
      quantity: request.quantity,
      status: request.status,
      inserted_at: request.inserted_at
    }

    raft_info =
      case request do
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
