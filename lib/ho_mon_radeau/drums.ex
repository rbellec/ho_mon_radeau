defmodule HoMonRadeau.Drums do
  @moduledoc """
  Context for managing drum (bidon) declarations, types, and settings.
  """

  import Ecto.Query

  alias HoMonRadeau.Repo
  alias HoMonRadeau.Drums.{DrumDeclaration, DrumDeclarationLine, DrumSettings, DrumType}

  ## Settings

  def get_settings do
    Repo.one(DrumSettings) || %DrumSettings{forfait_price: Decimal.new(5)}
  end

  def update_settings(attrs) do
    settings = Repo.one(DrumSettings) || %DrumSettings{}

    settings
    |> DrumSettings.changeset(attrs)
    |> Repo.insert_or_update()
  end

  def change_settings(settings \\ nil, attrs \\ %{}) do
    (settings || get_settings())
    |> DrumSettings.changeset(attrs)
  end

  ## Drum Types

  def list_drum_types do
    DrumType
    |> order_by([t], asc: t.position, asc: t.id)
    |> Repo.all()
  end

  def list_active_drum_types do
    DrumType
    |> where([t], t.active == true)
    |> order_by([t], asc: t.position, asc: t.id)
    |> Repo.all()
  end

  def get_drum_type!(id), do: Repo.get!(DrumType, id)

  def create_drum_type(attrs) do
    %DrumType{}
    |> DrumType.changeset(attrs)
    |> Repo.insert()
  end

  def update_drum_type(%DrumType{} = type, attrs) do
    type
    |> DrumType.changeset(attrs)
    |> Repo.update()
  end

  def change_drum_type(type \\ %DrumType{}, attrs \\ %{}) do
    DrumType.changeset(type, attrs)
  end

  ## Drum Declarations

  @doc """
  Gets the declaration for a crew, or returns a new empty one.
  """
  def get_or_build_declaration(crew_id) do
    DrumDeclaration
    |> where([d], d.crew_id == ^crew_id)
    |> preload(:lines)
    |> Repo.one()
    |> case do
      nil -> %DrumDeclaration{crew_id: crew_id, lines: []}
      declaration -> declaration
    end
  end

  @doc """
  Saves a draft declaration (declared = false if not yet submitted).
  """
  def save_declaration(crew_id, attrs) do
    declaration = get_or_build_declaration(crew_id)
    do_upsert_declaration(declaration, attrs, :changeset)
  end

  @doc """
  Submits a declaration (declared = true, declared_at set).
  """
  def submit_declaration(crew_id, attrs) do
    declaration = get_or_build_declaration(crew_id)
    do_upsert_declaration(declaration, attrs, :declare_changeset)
  end

  defp do_upsert_declaration(%DrumDeclaration{id: nil} = declaration, attrs, changeset_fn) do
    declaration
    |> build_changeset(changeset_fn, attrs)
    |> maybe_put_lines(attrs)
    |> Repo.insert()
  end

  defp do_upsert_declaration(%DrumDeclaration{} = declaration, attrs, changeset_fn) do
    declaration
    |> build_changeset(changeset_fn, attrs)
    |> maybe_put_lines(attrs)
    |> Repo.update()
  end

  defp build_changeset(declaration, :changeset, attrs) do
    DrumDeclaration.changeset(declaration, attrs)
  end

  defp build_changeset(declaration, :declare_changeset, attrs) do
    DrumDeclaration.declare_changeset(declaration, attrs)
  end

  defp maybe_put_lines(changeset, %{"mode" => "specific", "lines" => lines_attrs}) do
    types = list_active_drum_types()
    settings = get_settings()
    forfait = settings.forfait_price || Decimal.new(0)

    lines =
      Enum.map(types, fn type ->
        qty = Map.get(lines_attrs, Integer.to_string(type.id), "0") |> parse_int()
        price = type.unit_price || forfait

        %DrumDeclarationLine{
          drum_type_id: type.id,
          quantity: qty,
          unit_price_snapshot: price,
          subtotal: Decimal.mult(Decimal.new(qty), price)
        }
      end)

    Ecto.Changeset.put_assoc(changeset, :lines, lines)
  end

  defp maybe_put_lines(changeset, _attrs), do: changeset

  defp parse_int(val) when is_binary(val) do
    case Integer.parse(val) do
      {n, _} when n >= 0 -> n
      _ -> 0
    end
  end

  defp parse_int(val) when is_integer(val) and val >= 0, do: val
  defp parse_int(_), do: 0

  @doc """
  Returns a changeset for the declaration form.
  """
  def change_declaration(declaration \\ %DrumDeclaration{}, attrs \\ %{}) do
    DrumDeclaration.changeset(declaration, attrs)
  end

  @doc """
  Validates payment for a declaration.
  """
  def validate_payment(%DrumDeclaration{} = declaration, validated_by_id) do
    declaration
    |> DrumDeclaration.payment_changeset(validated_by_id)
    |> Repo.update()
  end

  @doc """
  Gets a declaration by ID with crew and raft preloaded.
  """
  def get_declaration!(id) do
    DrumDeclaration
    |> Repo.get!(id)
    |> Repo.preload(crew: :raft, lines: :drum_type)
  end

  @doc """
  Lists all declarations for admin view, with raft + lines + types preloaded.
  Only returns declarations from crews with an associated raft (not transverse teams).
  """
  def list_all_declarations do
    from(d in DrumDeclaration,
      join: c in assoc(d, :crew),
      join: r in assoc(c, :raft),
      preload: [crew: {c, raft: r}, lines: :drum_type],
      order_by: [asc: r.name]
    )
    |> Repo.all()
  end

  @doc """
  Lists all rafts (from validated or not) with their declaration status for admin overview.
  Returns a list of maps with raft, declaration (or nil), and total by type.
  """
  def list_rafts_with_declarations(edition_id) do
    rafts_query =
      from(r in HoMonRadeau.Events.Raft,
        where: r.edition_id == ^edition_id,
        join: c in assoc(r, :crew),
        left_join: d in DrumDeclaration,
        on: d.crew_id == c.id,
        left_join: lines in assoc(d, :lines),
        left_join: t in assoc(lines, :drum_type),
        preload: [crew: {c, []}],
        select: {r, d},
        order_by: [asc: r.name]
      )

    Repo.all(rafts_query)
  end

  @doc """
  Builds CSV content for drum declarations export.
  """
  def build_csv(edition_id) do
    types = list_active_drum_types()
    declarations = list_all_declarations()

    declarations_by_crew =
      Map.new(declarations, fn d -> {d.crew_id, d} end)

    rafts_with_crews =
      from(r in HoMonRadeau.Events.Raft,
        where: r.edition_id == ^edition_id,
        join: c in assoc(r, :crew),
        preload: [crew: c],
        order_by: [asc: r.name]
      )
      |> Repo.all()

    type_headers = Enum.map(types, & &1.name)

    headers =
      ["Nom du radeau", "Radeau validé", "Bidons déclarés"] ++
        type_headers ++ ["Total bidons", "Prix total (€)"]

    rows =
      Enum.map(rafts_with_crews, fn raft ->
        declaration = declarations_by_crew[raft.crew.id]

        validated = if raft.validated, do: "oui", else: "non"
        declared = if declaration && declaration.declared, do: "oui", else: "non"

        {type_quantities, total_qty} =
          if declaration && declaration.declared do
            case declaration.mode do
              "specific" ->
                lines_by_type =
                  Map.new(declaration.lines, fn l -> {l.drum_type_id, l.quantity} end)

                qtys = Enum.map(types, fn t -> lines_by_type[t.id] || 0 end)
                {qtys, Enum.sum(qtys)}

              "simple" ->
                {Enum.map(types, fn _ -> "" end), declaration.total_quantity || 0}
            end
          else
            {Enum.map(types, fn _ -> "" end), ""}
          end

        total_amount =
          if declaration && declaration.declared do
            declaration.total_amount || ""
          else
            ""
          end

        [raft.name, validated, declared] ++ type_quantities ++ [total_qty, total_amount]
      end)

    [headers | rows]
    |> Enum.map_join("\n", fn row ->
      Enum.map_join(row, ",", fn cell ->
        val = to_string(cell)

        if String.contains?(val, [",", "\""]),
          do: "\"#{String.replace(val, "\"", "\"\"")}\"",
          else: val
      end)
    end)
  end

  ## Stats helpers

  def compute_stats(declarations) do
    declared = Enum.filter(declarations, & &1.declared)
    paid = Enum.filter(declarations, &(&1.status == "paid"))

    %{
      total_declared: length(declared),
      total_paid: length(paid),
      total_paid_amount:
        paid
        |> Enum.map(& &1.total_amount)
        |> Enum.reject(&is_nil/1)
        |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
    }
  end
end
