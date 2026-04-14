defmodule HoMonRadeauWeb.Api.RegistrationFormController do
  use HoMonRadeauWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias HoMonRadeau.Events

  tags(["Registration Forms"])

  operation(:index,
    summary: "List registration forms",
    parameters: [
      status: [in: :query, type: :string, required: false],
      raft_id: [in: :query, type: :integer, required: false]
    ],
    responses: [ok: {"Form list", "application/json", :map}]
  )

  def index(conn, params) do
    edition = Events.get_current_edition()

    filters =
      params
      |> Map.take(~w(status raft_id))
      |> Enum.reject(fn {_, v} -> is_nil(v) or v == "" end)
      |> Map.new()

    forms = Events.list_registration_forms(edition, filters)
    json(conn, %{data: Enum.map(forms, &serialize_form/1)})
  end

  operation(:approve,
    summary: "Approve a registration form",
    parameters: [id: [in: :path, type: :integer, required: true]],
    responses: [ok: {"Approved form", "application/json", :map}]
  )

  def approve(conn, %{"id" => id}) do
    form = Events.get_registration_form!(id)

    case Events.approve_registration_form(form, conn.assigns.current_user) do
      {:ok, form} -> json(conn, %{data: serialize_form(form)})
      {:error, changeset} -> json_error(conn, changeset)
    end
  end

  operation(:reject,
    summary: "Reject a registration form",
    parameters: [id: [in: :path, type: :integer, required: true]],
    responses: [ok: {"Rejected form", "application/json", :map}]
  )

  def reject(conn, %{"id" => id}) do
    form = Events.get_registration_form!(id)
    reason = Map.get(conn.body_params, "reason", "")

    case Events.reject_registration_form(form, conn.assigns.current_user, reason) do
      {:ok, form} -> json(conn, %{data: serialize_form(form)})
      {:error, changeset} -> json_error(conn, changeset)
    end
  end

  defp serialize_form(form) do
    %{
      id: form.id,
      status: form.status,
      form_type: form.form_type,
      rejection_reason: form.rejection_reason,
      user_display_name:
        if(Ecto.assoc_loaded?(form.user),
          do: HoMonRadeau.Accounts.display_name(form.user),
          else: nil
        ),
      inserted_at: form.inserted_at,
      updated_at: form.updated_at
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
