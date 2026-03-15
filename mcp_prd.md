# PRD — Serveur MCP Admin HoMonRadeau

> Serveur Model Context Protocol pour administrer l'événement Tutto Blu via un outil IA (Claude Code / Claude Desktop).

## 1. Objectif

Permettre à un admin d'utiliser Claude (ou tout client MCP) pour gérer l'événement de manière conversationnelle : valider des utilisateurs, gérer les radeaux, approuver des fiches, suivre les paiements, etc.

## 2. Stack technique

- **Librairie** : `hermes_mcp ~> 0.14.1` ([hex.pm](https://hex.pm/packages/hermes_mcp))
- **Transport** : STDIO (usage local, pas de serveur HTTP)
- **Entrypoint** : `mix mcp.server` (mix task)
- **Sécurité** : STDIO = accès local implicitement admin. Un helper `get_system_admin/0` récupère le premier admin en base pour les opérations nécessitant un `%User{}`.

## 3. Architecture

```
lib/ho_mon_radeau/mcp/
  server.ex                    # Module principal Hermes.Server
  helpers.ex                   # Sérialisation + get_system_admin/0
  tools/
    list_users.ex
    search_users.ex
    validate_user.ex
    invalidate_user.ex
    list_rafts.ex
    get_raft.ex
    validate_raft.ex
    invalidate_raft.ex
    list_crew_members.ex
    promote_manager.ex
    demote_manager.ex
    set_captain.ex
    remove_crew_member.ex
    list_join_requests.ex
    accept_join_request.ex
    reject_join_request.ex
    list_registration_forms.ex
    approve_registration_form.ex
    reject_registration_form.ex
    list_drum_requests.ex
    validate_drum_payment.ex
    update_drum_settings.ex
    list_cuf_declarations.ex
    validate_cuf_declaration.ex
    update_cuf_settings.ex
    list_transverse_teams.ex
    create_transverse_team.ex
    add_team_member.ex
    remove_team_member.ex
  resources/
    users_summary.ex
    rafts_overview.ex
    registration_form_stats.ex
    drum_summary.ex
    cuf_stats.ex
    edition_info.ex

lib/mix/tasks/mcp.server.ex   # Entrypoint mix mcp.server
```

## 4. Module principal (server.ex)

```elixir
defmodule HoMonRadeau.MCP.Server do
  use Hermes.Server,
    name: "ho-mon-radeau-admin",
    version: "1.0.0",
    capabilities: [:tools, :resources]

  # Enregistrer chaque tool et resource comme component
  component HoMonRadeau.MCP.Tools.ListUsers
  component HoMonRadeau.MCP.Tools.SearchUsers
  # ... etc pour chaque module
end
```

## 5. Helpers (helpers.ex)

Fonctions de sérialisation partagées entre les tools :

- `serialize_user(user)` → `%{id, email, nickname, display_name, validated, first_name, last_name}`
- `serialize_raft(raft)` → `%{id, name, slug, validated, description_short, crew_count}`
- `serialize_crew_member(member)` → `%{user_id, display_name, is_manager, is_captain, roles}`
- `serialize_join_request(request)` → `%{id, user_display_name, message, status, inserted_at}`
- `serialize_registration_form(form)` → `%{id, user_email, form_type, status, file_name, uploaded_at}`
- `serialize_drum_request(request)` → `%{id, raft_name, quantity, total_amount, status}`
- `serialize_cuf_declaration(decl)` → `%{id, raft_name, participant_count, total_amount, status}`
- `serialize_transverse_team(team)` → `%{id, name, transverse_type, member_count}`
- `get_system_admin()` → récupère le premier `%User{is_admin: true}` en base

## 6. Catalogue des tools

Chaque tool implémente `Hermes.Server.Behaviour.Tool` avec `name/0`, `description/0`, `input_schema/0`, `execute/2`.

### 6.1 Utilisateurs

| Tool | Description | Paramètres | Fonction appelée |
|------|-------------|------------|------------------|
| `list_users` | Lister les utilisateurs. Filtrer par statut : all, pending, validated. | `filter` (string, opt, défaut "all") | `Accounts.list_all_users/0`, `list_pending_validation_users/0`, `list_validated_users/0` |
| `search_users` | Rechercher des utilisateurs par pseudo ou email. | `query` (string, requis) | `Accounts.search_users/1` |
| `validate_user` | Valider un utilisateur (accorder l'accès à l'événement). | `user_id` (integer, requis) | `Accounts.get_user!/1` → `Accounts.validate_user/1` |
| `invalidate_user` | Révoquer la validation d'un utilisateur. | `user_id` (integer, requis) | `Accounts.get_user!/1` → `Accounts.invalidate_user/1` |

### 6.2 Radeaux

| Tool | Description | Paramètres | Fonction appelée |
|------|-------------|------------|------------------|
| `list_rafts` | Lister les radeaux de l'édition courante. | `status` (string, opt : "validated"/"proposed"), `name` (string, opt) | `Events.list_admin_rafts/1` |
| `get_raft` | Obtenir les détails d'un radeau : équipage, capitaine, liens. | `raft_id` (integer, requis) | `Events.get_raft!/1` → `Events.preload_raft_details/1` |
| `validate_raft` | Valider un radeau (marquer comme participant). | `raft_id` (integer, requis) | `Events.validate_raft/2` avec system admin |
| `invalidate_raft` | Invalider un radeau (repasser en proposé). | `raft_id` (integer, requis) | `Events.invalidate_raft/1` |

### 6.3 Équipage

| Tool | Description | Paramètres | Fonction appelée |
|------|-------------|------------|------------------|
| `list_crew_members` | Lister les membres d'un équipage. | `crew_id` (integer, requis) | `Events.list_crew_members/1` |
| `promote_manager` | Promouvoir un membre en gestionnaire. | `crew_id`, `user_id` (integers, requis) | `Events.promote_to_manager/2` |
| `demote_manager` | Rétrograder un gestionnaire en membre. | `crew_id`, `user_id` (integers, requis) | `Events.demote_from_manager/2` |
| `set_captain` | Définir le capitaine d'un équipage. | `crew_id`, `user_id` (integers, requis) | `Events.set_captain/2` |
| `remove_crew_member` | Retirer un membre d'un équipage. | `crew_id`, `user_id` (integers, requis) | `Events.leave_crew/3` avec `removed_by_id: system_admin.id` |

### 6.4 Demandes d'embarquement

| Tool | Description | Paramètres | Fonction appelée |
|------|-------------|------------|------------------|
| `list_join_requests` | Lister les demandes en attente pour un équipage. | `crew_id` (integer, requis) | `Events.list_pending_join_requests/1` (besoin du struct Crew) |
| `accept_join_request` | Accepter une demande d'embarquement. | `request_id` (integer, requis) | `Events.get_join_request!/1` → `Events.accept_join_request/2` |
| `reject_join_request` | Refuser une demande d'embarquement. | `request_id` (integer, requis) | `Events.get_join_request!/1` → `Events.reject_join_request/2` |

### 6.5 Fiches d'inscription

| Tool | Description | Paramètres | Fonction appelée |
|------|-------------|------------|------------------|
| `list_registration_forms` | Lister les fiches d'inscription. Filtrer par statut et radeau. | `status` (string, opt : "pending"/"approved"/"rejected"), `raft_id` (integer, opt) | `Events.list_registration_forms/2` |
| `approve_registration_form` | Approuver une fiche d'inscription. | `form_id` (integer, requis) | `Events.get_registration_form!/1` → `Events.approve_registration_form/2` avec system admin |
| `reject_registration_form` | Rejeter une fiche avec un motif. | `form_id` (integer, requis), `reason` (string, requis) | `Events.get_registration_form!/1` → `Events.reject_registration_form/3` avec system admin |

### 6.6 Bidons

| Tool | Description | Paramètres | Fonction appelée |
|------|-------------|------------|------------------|
| `list_drum_requests` | Lister les commandes de bidons. | `status` (string, opt : "pending"/"paid"/"all") | `Drums.list_all_requests/1` |
| `validate_drum_payment` | Valider le paiement d'une commande. | `request_id` (integer, requis) | `Drums.get_request!/1` → `Drums.validate_payment/2` avec system admin id |
| `update_drum_settings` | Modifier les paramètres bidons (prix, RIB). | `unit_price` (number, opt), `rib_iban` (string, opt), `rib_bic` (string, opt) | `Drums.update_settings/1` |

### 6.7 CUF

| Tool | Description | Paramètres | Fonction appelée |
|------|-------------|------------|------------------|
| `list_cuf_declarations` | Lister les déclarations CUF. | `status` (string, opt : "pending"/"validated"/"all") | `CUF.list_all_declarations/1` |
| `validate_cuf_declaration` | Valider une déclaration CUF. | `declaration_id` (integer, requis) | `CUF.get_declaration!/1` → `CUF.validate_declaration/2` avec system admin id |
| `update_cuf_settings` | Modifier les paramètres CUF. | `unit_price` (number, opt), `total_limit` (integer, opt), `rib_iban` (string, opt), `rib_bic` (string, opt) | `CUF.update_settings/1` |

### 6.8 Équipes transverses

| Tool | Description | Paramètres | Fonction appelée |
|------|-------------|------------|------------------|
| `list_transverse_teams` | Lister les équipes transverses avec le nombre de membres. | (aucun) | `Events.list_transverse_teams/0` |
| `create_transverse_team` | Créer une équipe transverse. | `name` (string, requis), `description` (string, opt), `transverse_type` (string, opt) | `Events.create_transverse_team/1` |
| `add_team_member` | Ajouter un membre à une équipe transverse. | `team_id`, `user_id` (integers, requis), `is_manager` (boolean, opt) | `Events.add_transverse_team_member/3` |
| `remove_team_member` | Retirer un membre d'une équipe transverse. | `team_id`, `user_id` (integers, requis) | `Events.remove_transverse_team_member/2` |

## 7. Catalogue des resources

Chaque resource implémente `Hermes.Server.Behaviour.Resource` avec `uri/0`, `name/0`, `description/0`, `mime_type/0`, `read/2`. Toutes retournent `application/json`.

| URI | Nom | Description | Données |
|-----|-----|-------------|---------|
| `ho-mon-radeau://users/summary` | Résumé utilisateurs | Stats : total, validés, en attente. | Compteurs depuis `Accounts.list_all_users/0` etc. |
| `ho-mon-radeau://rafts/overview` | Vue d'ensemble radeaux | Liste des radeaux avec membres et statut. | `Events.list_admin_rafts/1` sérialisé |
| `ho-mon-radeau://forms/stats` | Stats fiches d'inscription | Statistiques par radeau. | `Events.registration_form_stats_by_raft/1` |
| `ho-mon-radeau://drums/summary` | Résumé bidons | Commandes + paramètres. | `Drums.get_settings/0` + `Drums.list_all_requests/1` agrégé |
| `ho-mon-radeau://cuf/stats` | Stats CUF | Participation CUF. | `CUF.get_participant_stats/0` + `CUF.get_settings/0` |
| `ho-mon-radeau://edition/current` | Édition courante | Infos de l'édition en cours. | `Events.get_current_edition/0` |

## 8. Entrypoint : mix mcp.server

```elixir
defmodule Mix.Tasks.Mcp.Server do
  use Mix.Task

  @shortdoc "Démarrer le serveur MCP (transport stdio)"

  def run(_args) do
    # Démarrer l'app complète (Repo, etc.) SANS le endpoint web
    Application.put_env(:ho_mon_radeau, HoMonRadeauWeb.Endpoint, server: false)
    {:ok, _} = Application.ensure_all_started(:ho_mon_radeau)

    # Démarrer le serveur MCP
    {:ok, _pid} = Hermes.Server.start_link(
      HoMonRadeau.MCP.Server, [],
      transport: :stdio
    )

    # Garder le process en vie
    Process.sleep(:infinity)
  end
end
```

## 9. Configuration Claude Code / Desktop

```json
{
  "mcpServers": {
    "ho-mon-radeau": {
      "command": "docker",
      "args": ["compose", "run", "--rm", "-T", "app", "mix", "mcp.server"],
      "cwd": "/chemin/vers/ho_mon_radeau"
    }
  }
}
```

Note : le flag `-T` désactive le pseudo-TTY, nécessaire pour le transport STDIO.

## 10. Étapes d'implémentation

### Étape 1 : Setup
- Ajouter `{:hermes_mcp, "~> 0.14.1"}` dans `mix.exs`
- `docker compose run --rm app mix deps.get`
- Vérifier que la lib compile : `docker compose run --rm app mix compile`

### Étape 2 : Helpers et server (squelette)
- Créer `lib/ho_mon_radeau/mcp/helpers.ex` avec toutes les fonctions de sérialisation
- Créer `lib/ho_mon_radeau/mcp/server.ex` avec `use Hermes.Server` (vide d'abord)
- Créer `lib/mix/tasks/mcp.server.ex`
- Tester que `mix mcp.server` démarre sans erreur

### Étape 3 : Tools utilisateurs (4 modules)
- `list_users`, `search_users`, `validate_user`, `invalidate_user`
- Enregistrer dans server.ex, tester manuellement

### Étape 4 : Tools radeaux (4 modules)
- `list_rafts`, `get_raft`, `validate_raft`, `invalidate_raft`

### Étape 5 : Tools équipage (5 modules)
- `list_crew_members`, `promote_manager`, `demote_manager`, `set_captain`, `remove_crew_member`

### Étape 6 : Tools demandes + fiches (6 modules)
- `list_join_requests`, `accept_join_request`, `reject_join_request`
- `list_registration_forms`, `approve_registration_form`, `reject_registration_form`

### Étape 7 : Tools finances (6 modules)
- `list_drum_requests`, `validate_drum_payment`, `update_drum_settings`
- `list_cuf_declarations`, `validate_cuf_declaration`, `update_cuf_settings`

### Étape 8 : Tools équipes transverses (4 modules)
- `list_transverse_teams`, `create_transverse_team`, `add_team_member`, `remove_team_member`

### Étape 9 : Resources (6 modules)
- `users_summary`, `rafts_overview`, `registration_form_stats`, `drum_summary`, `cuf_stats`, `edition_info`

### Étape 10 : Tests et documentation
- Tester chaque tool via Claude Code
- Vérifier que les resources retournent des données cohérentes
- Documenter la configuration dans le README

## 11. Points d'attention

1. **Admin système** : `get_system_admin/0` nécessite au moins un admin en base. Le mix task doit avertir si aucun admin n'existe.
2. **Logging** : Logger écrit sur stderr par défaut, ce qui est compatible avec le transport STDIO (seuls stdin/stdout sont utilisés pour le protocole). Ne rien écrire sur stdout directement.
3. **Docker** : Le flag `-T` est indispensable pour que stdin/stdout soient correctement connectés.
4. **Stabilité hermes_mcp** : La lib est en v0.14.x et évolue. Épingler la version précisément.
5. **Pas de modifications du code métier** : Le serveur MCP est une couche par-dessus les contextes existants. Aucune modification des modules Accounts, Events, Drums, CUF n'est nécessaire.

## 12. Total des modules à créer

- 1 module server
- 1 module helpers
- 29 modules tools
- 6 modules resources
- 1 mix task
- **Total : 38 fichiers**
