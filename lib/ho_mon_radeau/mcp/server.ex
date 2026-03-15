defmodule HoMonRadeau.MCP.Server do
  @moduledoc """
  MCP Server for AI-powered admin management of HoMonRadeau.
  Exposes tools and resources for managing users, rafts, crews,
  registration forms, drums, CUF, and transverse teams.
  """
  use ExMCP.Server

  alias HoMonRadeau.{Accounts, Events, Drums, CUF}
  alias HoMonRadeau.MCP.Helpers

  # ============================================================
  # TOOLS — Users
  # ============================================================

  deftool "list_users" do
    meta do
      description("Lister les utilisateurs. Filtrer par statut : all, pending, validated.")
    end

    input_schema(%{
      type: "object",
      properties: %{
        filter: %{type: "string", enum: ["all", "pending", "validated"], description: "Statut"}
      }
    })
  end

  deftool "search_users" do
    meta do
      description("Rechercher des utilisateurs par pseudo ou email.")
    end

    input_schema(%{
      type: "object",
      properties: %{query: %{type: "string", description: "Terme de recherche"}},
      required: ["query"]
    })
  end

  deftool "validate_user" do
    meta do
      description("Valider un utilisateur (accorder l'accès à l'événement).")
    end

    input_schema(%{
      type: "object",
      properties: %{user_id: %{type: "integer", description: "ID utilisateur"}},
      required: ["user_id"]
    })
  end

  deftool "invalidate_user" do
    meta do
      description("Révoquer la validation d'un utilisateur.")
    end

    input_schema(%{
      type: "object",
      properties: %{user_id: %{type: "integer", description: "ID utilisateur"}},
      required: ["user_id"]
    })
  end

  # ============================================================
  # TOOLS — Rafts
  # ============================================================

  deftool "list_rafts" do
    meta do
      description("Lister les radeaux de l'édition courante. Filtrer par statut et nom.")
    end

    input_schema(%{
      type: "object",
      properties: %{
        status: %{type: "string", enum: ["all", "validated", "proposed"], description: "Statut"},
        name: %{type: "string", description: "Filtrer par nom"}
      }
    })
  end

  deftool "get_raft" do
    meta do
      description("Obtenir les détails d'un radeau : équipage, capitaine, liens.")
    end

    input_schema(%{
      type: "object",
      properties: %{raft_id: %{type: "integer", description: "ID du radeau"}},
      required: ["raft_id"]
    })
  end

  deftool "validate_raft" do
    meta do
      description("Valider un radeau (marquer comme participant).")
    end

    input_schema(%{
      type: "object",
      properties: %{raft_id: %{type: "integer", description: "ID du radeau"}},
      required: ["raft_id"]
    })
  end

  deftool "invalidate_raft" do
    meta do
      description("Invalider un radeau (repasser en proposé).")
    end

    input_schema(%{
      type: "object",
      properties: %{raft_id: %{type: "integer", description: "ID du radeau"}},
      required: ["raft_id"]
    })
  end

  # ============================================================
  # TOOLS — Crew
  # ============================================================

  deftool "list_crew_members" do
    meta do
      description("Lister les membres d'un équipage.")
    end

    input_schema(%{
      type: "object",
      properties: %{crew_id: %{type: "integer", description: "ID de l'équipage"}},
      required: ["crew_id"]
    })
  end

  deftool "promote_manager" do
    meta do
      description("Promouvoir un membre en gestionnaire d'équipage.")
    end

    input_schema(%{
      type: "object",
      properties: %{
        crew_id: %{type: "integer", description: "ID de l'équipage"},
        user_id: %{type: "integer", description: "ID utilisateur"}
      },
      required: ["crew_id", "user_id"]
    })
  end

  deftool "demote_manager" do
    meta do
      description("Rétrograder un gestionnaire en membre simple.")
    end

    input_schema(%{
      type: "object",
      properties: %{
        crew_id: %{type: "integer", description: "ID de l'équipage"},
        user_id: %{type: "integer", description: "ID utilisateur"}
      },
      required: ["crew_id", "user_id"]
    })
  end

  deftool "set_captain" do
    meta do
      description("Définir le capitaine d'un équipage.")
    end

    input_schema(%{
      type: "object",
      properties: %{
        crew_id: %{type: "integer", description: "ID de l'équipage"},
        user_id: %{type: "integer", description: "ID utilisateur"}
      },
      required: ["crew_id", "user_id"]
    })
  end

  deftool "remove_crew_member" do
    meta do
      description("Retirer un membre d'un équipage (départ forcé).")
    end

    input_schema(%{
      type: "object",
      properties: %{
        crew_id: %{type: "integer", description: "ID de l'équipage"},
        user_id: %{type: "integer", description: "ID utilisateur"}
      },
      required: ["crew_id", "user_id"]
    })
  end

  # ============================================================
  # TOOLS — Join Requests
  # ============================================================

  deftool "list_join_requests" do
    meta do
      description("Lister les demandes d'embarquement en attente pour un équipage.")
    end

    input_schema(%{
      type: "object",
      properties: %{crew_id: %{type: "integer", description: "ID de l'équipage"}},
      required: ["crew_id"]
    })
  end

  deftool "accept_join_request" do
    meta do
      description("Accepter une demande d'embarquement.")
    end

    input_schema(%{
      type: "object",
      properties: %{request_id: %{type: "integer", description: "ID de la demande"}},
      required: ["request_id"]
    })
  end

  deftool "reject_join_request" do
    meta do
      description("Refuser une demande d'embarquement.")
    end

    input_schema(%{
      type: "object",
      properties: %{request_id: %{type: "integer", description: "ID de la demande"}},
      required: ["request_id"]
    })
  end

  # ============================================================
  # TOOLS — Registration Forms
  # ============================================================

  deftool "list_registration_forms" do
    meta do
      description("Lister les fiches d'inscription. Filtrer par statut et radeau.")
    end

    input_schema(%{
      type: "object",
      properties: %{
        status: %{
          type: "string",
          enum: ["pending", "approved", "rejected"],
          description: "Statut"
        },
        raft_id: %{type: "integer", description: "ID du radeau"}
      }
    })
  end

  deftool "approve_registration_form" do
    meta do
      description("Approuver une fiche d'inscription.")
    end

    input_schema(%{
      type: "object",
      properties: %{form_id: %{type: "integer", description: "ID de la fiche"}},
      required: ["form_id"]
    })
  end

  deftool "reject_registration_form" do
    meta do
      description("Rejeter une fiche d'inscription avec un motif.")
    end

    input_schema(%{
      type: "object",
      properties: %{
        form_id: %{type: "integer", description: "ID de la fiche"},
        reason: %{type: "string", description: "Motif du rejet"}
      },
      required: ["form_id", "reason"]
    })
  end

  # ============================================================
  # TOOLS — Drums
  # ============================================================

  deftool "list_drum_requests" do
    meta do
      description("Lister les commandes de bidons. Filtrer par statut.")
    end

    input_schema(%{
      type: "object",
      properties: %{
        status: %{type: "string", enum: ["all", "pending", "paid"], description: "Statut"}
      }
    })
  end

  deftool "validate_drum_payment" do
    meta do
      description("Valider le paiement d'une commande de bidons.")
    end

    input_schema(%{
      type: "object",
      properties: %{request_id: %{type: "integer", description: "ID de la commande"}},
      required: ["request_id"]
    })
  end

  deftool "update_drum_settings" do
    meta do
      description("Modifier les paramètres bidons (prix unitaire, RIB).")
    end

    input_schema(%{
      type: "object",
      properties: %{
        unit_price: %{type: "number", description: "Prix unitaire"},
        rib_iban: %{type: "string", description: "IBAN"},
        rib_bic: %{type: "string", description: "BIC"}
      }
    })
  end

  # ============================================================
  # TOOLS — CUF
  # ============================================================

  deftool "list_cuf_declarations" do
    meta do
      description("Lister les déclarations CUF. Filtrer par statut.")
    end

    input_schema(%{
      type: "object",
      properties: %{
        status: %{type: "string", enum: ["all", "pending", "validated"], description: "Statut"}
      }
    })
  end

  deftool "validate_cuf_declaration" do
    meta do
      description("Valider une déclaration CUF.")
    end

    input_schema(%{
      type: "object",
      properties: %{declaration_id: %{type: "integer", description: "ID de la déclaration"}},
      required: ["declaration_id"]
    })
  end

  deftool "update_cuf_settings" do
    meta do
      description("Modifier les paramètres CUF (prix unitaire, limite, RIB).")
    end

    input_schema(%{
      type: "object",
      properties: %{
        unit_price: %{type: "number", description: "Prix par participant"},
        total_limit: %{type: "integer", description: "Limite de participants"},
        rib_iban: %{type: "string", description: "IBAN"},
        rib_bic: %{type: "string", description: "BIC"}
      }
    })
  end

  # ============================================================
  # TOOLS — Transverse Teams
  # ============================================================

  deftool "list_transverse_teams" do
    meta do
      description("Lister les équipes transverses avec le nombre de membres.")
    end

    input_schema(%{type: "object", properties: %{}})
  end

  deftool "create_transverse_team" do
    meta do
      description("Créer une équipe transverse.")
    end

    input_schema(%{
      type: "object",
      properties: %{
        name: %{type: "string", description: "Nom de l'équipe"},
        description: %{type: "string", description: "Description"},
        transverse_type: %{
          type: "string",
          enum: [
            "welcome_team",
            "safe_team",
            "drums_team",
            "security",
            "medical",
            "other"
          ],
          description: "Type d'équipe"
        }
      },
      required: ["name"]
    })
  end

  deftool "add_team_member" do
    meta do
      description("Ajouter un membre à une équipe transverse.")
    end

    input_schema(%{
      type: "object",
      properties: %{
        team_id: %{type: "integer", description: "ID de l'équipe"},
        user_id: %{type: "integer", description: "ID utilisateur"},
        is_manager: %{type: "boolean", description: "Coordinateur ?"}
      },
      required: ["team_id", "user_id"]
    })
  end

  deftool "remove_team_member" do
    meta do
      description("Retirer un membre d'une équipe transverse.")
    end

    input_schema(%{
      type: "object",
      properties: %{
        team_id: %{type: "integer", description: "ID de l'équipe"},
        user_id: %{type: "integer", description: "ID utilisateur"}
      },
      required: ["team_id", "user_id"]
    })
  end

  # ============================================================
  # RESOURCES
  # ============================================================

  defresource "ho-mon-radeau://edition/current" do
    meta do
      name("Édition courante")
      description("Informations sur l'édition en cours.")
    end

    mime_type("application/json")
  end

  defresource "ho-mon-radeau://users/summary" do
    meta do
      name("Résumé utilisateurs")
      description("Statistiques des utilisateurs : total, validés, en attente.")
    end

    mime_type("application/json")
  end

  defresource "ho-mon-radeau://rafts/overview" do
    meta do
      name("Vue d'ensemble radeaux")
      description("Liste des radeaux avec membres et statut.")
    end

    mime_type("application/json")
  end

  defresource "ho-mon-radeau://forms/stats" do
    meta do
      name("Stats fiches d'inscription")
      description("Statistiques des fiches d'inscription par radeau.")
    end

    mime_type("application/json")
  end

  defresource "ho-mon-radeau://drums/summary" do
    meta do
      name("Résumé bidons")
      description("Commandes de bidons et paramètres.")
    end

    mime_type("application/json")
  end

  defresource "ho-mon-radeau://cuf/stats" do
    meta do
      name("Stats CUF")
      description("Statistiques de participation CUF.")
    end

    mime_type("application/json")
  end

  # ============================================================
  # TOOL HANDLERS
  # ============================================================

  @impl true
  def handle_tool_call("list_users", args, _state) do
    filter = Map.get(args, "filter", "all")

    users =
      case filter do
        "pending" -> Accounts.list_pending_validation_users()
        "validated" -> Accounts.list_validated_users()
        _ -> Accounts.list_all_users()
      end

    Helpers.ok_result(%{count: length(users), users: Enum.map(users, &Helpers.serialize_user/1)})
  end

  @impl true
  def handle_tool_call("search_users", %{"query" => query}, _state) do
    users = Accounts.search_users(query)
    Helpers.ok_result(%{count: length(users), users: Enum.map(users, &Helpers.serialize_user/1)})
  end

  @impl true
  def handle_tool_call("validate_user", %{"user_id" => id}, _state) do
    user = Accounts.get_user!(id)

    case Accounts.validate_user(user) do
      {:ok, user} ->
        Helpers.ok_result(%{message: "Utilisateur validé.", user: Helpers.serialize_user(user)})

      {:error, _} ->
        Helpers.error_result("Erreur lors de la validation.")
    end
  end

  @impl true
  def handle_tool_call("invalidate_user", %{"user_id" => id}, _state) do
    user = Accounts.get_user!(id)

    case Accounts.invalidate_user(user) do
      {:ok, user} ->
        Helpers.ok_result(%{
          message: "Validation révoquée.",
          user: Helpers.serialize_user(user)
        })

      {:error, _} ->
        Helpers.error_result("Erreur lors de la révocation.")
    end
  end

  @impl true
  def handle_tool_call("list_rafts", args, _state) do
    filters = %{}
    filters = if args["status"], do: Map.put(filters, "status", args["status"]), else: filters
    filters = if args["name"], do: Map.put(filters, "name", args["name"]), else: filters

    rafts = Events.list_admin_rafts(filters)

    Helpers.ok_result(%{
      count: length(rafts),
      rafts: Enum.map(rafts, &Helpers.serialize_raft/1)
    })
  end

  @impl true
  def handle_tool_call("get_raft", %{"raft_id" => id}, _state) do
    raft = Events.get_raft!(id) |> Events.preload_raft_details()
    Helpers.ok_result(Helpers.serialize_raft_detail(raft))
  end

  @impl true
  def handle_tool_call("validate_raft", %{"raft_id" => id}, _state) do
    admin = Helpers.get_current_admin()
    raft = Events.get_raft!(id)

    case Events.validate_raft(raft, admin) do
      {:ok, raft} ->
        Helpers.ok_result(%{message: "Radeau validé.", raft: Helpers.serialize_raft(raft)})

      {:error, _} ->
        Helpers.error_result("Erreur lors de la validation du radeau.")
    end
  end

  @impl true
  def handle_tool_call("invalidate_raft", %{"raft_id" => id}, _state) do
    raft = Events.get_raft!(id)

    case Events.invalidate_raft(raft) do
      {:ok, raft} ->
        Helpers.ok_result(%{message: "Radeau invalidé.", raft: Helpers.serialize_raft(raft)})

      {:error, _} ->
        Helpers.error_result("Erreur lors de l'invalidation du radeau.")
    end
  end

  @impl true
  def handle_tool_call("list_crew_members", %{"crew_id" => crew_id}, _state) do
    members = Events.list_crew_members(crew_id)

    Helpers.ok_result(%{
      count: length(members),
      members: Enum.map(members, &Helpers.serialize_crew_member/1)
    })
  end

  @impl true
  def handle_tool_call("promote_manager", %{"crew_id" => crew_id, "user_id" => user_id}, _state) do
    case Events.promote_to_manager(crew_id, user_id) do
      {:ok, _} -> Helpers.ok_result(%{message: "Membre promu gestionnaire."})
      {:error, _} -> Helpers.error_result("Erreur lors de la promotion.")
    end
  end

  @impl true
  def handle_tool_call("demote_manager", %{"crew_id" => crew_id, "user_id" => user_id}, _state) do
    case Events.demote_from_manager(crew_id, user_id) do
      {:ok, _} -> Helpers.ok_result(%{message: "Gestionnaire rétrogradé."})
      {:error, _} -> Helpers.error_result("Erreur lors de la rétrogradation.")
    end
  end

  @impl true
  def handle_tool_call("set_captain", %{"crew_id" => crew_id, "user_id" => user_id}, _state) do
    case Events.set_captain(crew_id, user_id) do
      {:ok, _} -> Helpers.ok_result(%{message: "Capitaine défini."})
      {:error, _} -> Helpers.error_result("Erreur lors de la nomination du capitaine.")
    end
  end

  @impl true
  def handle_tool_call(
        "remove_crew_member",
        %{"crew_id" => crew_id, "user_id" => user_id},
        _state
      ) do
    admin = Helpers.get_current_admin()

    case Events.leave_crew(user_id, crew_id, removed_by_id: admin.id) do
      {:ok, _} -> Helpers.ok_result(%{message: "Membre retiré de l'équipage."})
      {:error, _} -> Helpers.error_result("Erreur lors du retrait.")
    end
  end

  @impl true
  def handle_tool_call("list_join_requests", %{"crew_id" => crew_id}, _state) do
    crew = %{id: crew_id}
    requests = Events.list_pending_join_requests(crew)

    Helpers.ok_result(%{
      count: length(requests),
      requests: Enum.map(requests, &Helpers.serialize_join_request/1)
    })
  end

  @impl true
  def handle_tool_call("accept_join_request", %{"request_id" => id}, _state) do
    admin = Helpers.get_current_admin()
    request = Events.get_join_request!(id)

    case Events.accept_join_request(request, admin) do
      {:ok, _} -> Helpers.ok_result(%{message: "Demande acceptée."})
      {:error, :user_not_validated} -> Helpers.error_result("L'utilisateur n'est pas validé.")
      {:error, _} -> Helpers.error_result("Erreur lors de l'acceptation.")
    end
  end

  @impl true
  def handle_tool_call("reject_join_request", %{"request_id" => id}, _state) do
    admin = Helpers.get_current_admin()
    request = Events.get_join_request!(id)

    case Events.reject_join_request(request, admin) do
      {:ok, _} -> Helpers.ok_result(%{message: "Demande refusée."})
      {:error, _} -> Helpers.error_result("Erreur lors du refus.")
    end
  end

  @impl true
  def handle_tool_call("list_registration_forms", args, _state) do
    edition = Events.get_current_edition()

    if edition do
      opts =
        []
        |> then(fn o ->
          if args["status"], do: Keyword.put(o, :status, args["status"]), else: o
        end)
        |> then(fn o ->
          if args["raft_id"], do: Keyword.put(o, :raft_id, args["raft_id"]), else: o
        end)

      forms = Events.list_registration_forms(edition.id, opts)

      Helpers.ok_result(%{
        count: length(forms),
        forms: Enum.map(forms, &Helpers.serialize_registration_form/1)
      })
    else
      Helpers.error_result("Aucune édition en cours.")
    end
  end

  @impl true
  def handle_tool_call("approve_registration_form", %{"form_id" => id}, _state) do
    admin = Helpers.get_current_admin()
    form = Events.get_registration_form!(id)

    case Events.approve_registration_form(form, admin) do
      {:ok, _} -> Helpers.ok_result(%{message: "Fiche approuvée."})
      {:error, _} -> Helpers.error_result("Erreur lors de l'approbation.")
    end
  end

  @impl true
  def handle_tool_call(
        "reject_registration_form",
        %{"form_id" => id, "reason" => reason},
        _state
      ) do
    admin = Helpers.get_current_admin()
    form = Events.get_registration_form!(id)

    case Events.reject_registration_form(form, admin, reason) do
      {:ok, _} -> Helpers.ok_result(%{message: "Fiche rejetée."})
      {:error, _} -> Helpers.error_result("Erreur lors du rejet.")
    end
  end

  @impl true
  def handle_tool_call("list_drum_requests", args, _state) do
    filter =
      case Map.get(args, "status", "all") do
        "all" -> nil
        status -> status
      end

    requests = Drums.list_all_requests(filter)

    Helpers.ok_result(%{
      count: length(requests),
      requests: Enum.map(requests, &Helpers.serialize_drum_request/1)
    })
  end

  @impl true
  def handle_tool_call("validate_drum_payment", %{"request_id" => id}, _state) do
    admin = Helpers.get_current_admin()
    request = Drums.get_request!(id)

    case Drums.validate_payment(request, admin.id) do
      {:ok, _} -> Helpers.ok_result(%{message: "Paiement validé."})
      {:error, _} -> Helpers.error_result("Erreur lors de la validation du paiement.")
    end
  end

  @impl true
  def handle_tool_call("update_drum_settings", args, _state) do
    attrs =
      args
      |> Map.take(["unit_price", "rib_iban", "rib_bic"])
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new()

    case Drums.update_settings(attrs) do
      {:ok, settings} ->
        Helpers.ok_result(%{
          message: "Paramètres bidons mis à jour.",
          unit_price: to_string(settings.unit_price)
        })

      {:error, _} ->
        Helpers.error_result("Erreur lors de la mise à jour des paramètres.")
    end
  end

  @impl true
  def handle_tool_call("list_cuf_declarations", args, _state) do
    filter =
      case Map.get(args, "status", "all") do
        "all" -> nil
        status -> status
      end

    declarations = CUF.list_all_declarations(filter)

    Helpers.ok_result(%{
      count: length(declarations),
      declarations: Enum.map(declarations, &Helpers.serialize_cuf_declaration/1)
    })
  end

  @impl true
  def handle_tool_call("validate_cuf_declaration", %{"declaration_id" => id}, _state) do
    admin = Helpers.get_current_admin()
    declaration = CUF.get_declaration!(id)

    case CUF.validate_declaration(declaration, admin.id) do
      {:ok, _} -> Helpers.ok_result(%{message: "Déclaration CUF validée."})
      {:error, _} -> Helpers.error_result("Erreur lors de la validation CUF.")
    end
  end

  @impl true
  def handle_tool_call("update_cuf_settings", args, _state) do
    attrs =
      args
      |> Map.take(["unit_price", "total_limit", "rib_iban", "rib_bic"])
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new()

    case CUF.update_settings(attrs) do
      {:ok, settings} ->
        Helpers.ok_result(%{
          message: "Paramètres CUF mis à jour.",
          unit_price: to_string(settings.unit_price)
        })

      {:error, _} ->
        Helpers.error_result("Erreur lors de la mise à jour des paramètres CUF.")
    end
  end

  @impl true
  def handle_tool_call("list_transverse_teams", _args, _state) do
    teams = Events.list_transverse_teams()

    Helpers.ok_result(%{
      count: length(teams),
      teams: Enum.map(teams, &Helpers.serialize_transverse_team/1)
    })
  end

  @impl true
  def handle_tool_call("create_transverse_team", args, _state) do
    edition = Events.get_current_edition()

    attrs =
      %{edition_id: edition && edition.id, is_transverse: true}
      |> Map.merge(%{
        name: args["name"],
        description: args["description"],
        transverse_type: args["transverse_type"]
      })

    case Events.create_transverse_team(attrs) do
      {:ok, team} ->
        Helpers.ok_result(%{
          message: "Équipe transverse créée.",
          team: Helpers.serialize_transverse_team(team)
        })

      {:error, _} ->
        Helpers.error_result("Erreur lors de la création de l'équipe.")
    end
  end

  @impl true
  def handle_tool_call("add_team_member", args, _state) do
    opts = if args["is_manager"], do: [is_manager: true], else: []

    case Events.add_transverse_team_member(args["team_id"], args["user_id"], opts) do
      {:ok, _} -> Helpers.ok_result(%{message: "Membre ajouté à l'équipe."})
      {:error, _} -> Helpers.error_result("Erreur lors de l'ajout.")
    end
  end

  @impl true
  def handle_tool_call(
        "remove_team_member",
        %{"team_id" => team_id, "user_id" => user_id},
        _state
      ) do
    case Events.remove_transverse_team_member(team_id, user_id) do
      {:ok, _} -> Helpers.ok_result(%{message: "Membre retiré de l'équipe."})
      {:error, _} -> Helpers.error_result("Erreur lors du retrait.")
    end
  end

  # Catch-all for unknown tools
  @impl true
  def handle_tool_call(name, _args, _state) do
    Helpers.error_result("Outil inconnu : #{name}")
  end

  # ============================================================
  # RESOURCE HANDLERS
  # ============================================================

  @impl true
  def handle_resource_read("ho-mon-radeau://edition/current", _uri, state) do
    case Events.get_current_edition() do
      nil ->
        {:ok, [%{type: "text", text: Jason.encode!(%{message: "Aucune édition en cours."})}],
         state}

      edition ->
        data = %{
          id: edition.id,
          year: edition.year,
          name: edition.name,
          start_date: to_string(edition.start_date),
          end_date: to_string(edition.end_date),
          registration_deadline: to_string(edition.registration_deadline)
        }

        {:ok, [%{type: "text", text: Jason.encode!(data, pretty: true)}], state}
    end
  end

  @impl true
  def handle_resource_read("ho-mon-radeau://users/summary", _uri, state) do
    all = Accounts.list_all_users()
    pending = Accounts.list_pending_validation_users()
    validated = Accounts.list_validated_users()

    data = %{
      total: length(all),
      validated: length(validated),
      pending: length(pending)
    }

    {:ok, [%{type: "text", text: Jason.encode!(data, pretty: true)}], state}
  end

  @impl true
  def handle_resource_read("ho-mon-radeau://rafts/overview", _uri, state) do
    edition = Events.get_current_edition()

    rafts =
      if edition do
        Events.list_admin_rafts(%{})
        |> Enum.map(&Helpers.serialize_raft/1)
      else
        []
      end

    {:ok,
     [%{type: "text", text: Jason.encode!(%{count: length(rafts), rafts: rafts}, pretty: true)}],
     state}
  end

  @impl true
  def handle_resource_read("ho-mon-radeau://forms/stats", _uri, state) do
    edition = Events.get_current_edition()

    data =
      if edition do
        Events.registration_form_stats_by_raft(edition.id)
      else
        []
      end

    {:ok, [%{type: "text", text: Jason.encode!(data, pretty: true)}], state}
  end

  @impl true
  def handle_resource_read("ho-mon-radeau://drums/summary", _uri, state) do
    settings = Drums.get_settings()
    requests = Drums.list_all_requests(nil)

    paid = Enum.filter(requests, &(&1.status == "paid"))
    pending = Enum.filter(requests, &(&1.status == "pending"))

    data = %{
      settings: %{unit_price: to_string(settings.unit_price), rib_iban: settings.rib_iban},
      paid_count: length(paid),
      pending_count: length(pending),
      total_requests: length(requests)
    }

    {:ok, [%{type: "text", text: Jason.encode!(data, pretty: true)}], state}
  end

  @impl true
  def handle_resource_read("ho-mon-radeau://cuf/stats", _uri, state) do
    settings = CUF.get_settings()
    stats = CUF.get_participant_stats()

    data = %{
      settings: %{
        unit_price: to_string(settings.unit_price),
        total_limit: settings.total_limit,
        rib_iban: settings.rib_iban
      },
      validated_participants: stats.total_validated,
      limit: stats.limit
    }

    {:ok, [%{type: "text", text: Jason.encode!(data, pretty: true)}], state}
  end

  @impl true
  def handle_resource_read(uri, _full_uri, state) do
    {:error, "Ressource inconnue : #{uri}", state}
  end
end
