# Serveur MCP — Administration HoMonRadeau

Serveur [Model Context Protocol](https://modelcontextprotocol.io/) permettant d'administrer l'événement Tutto Blu via un outil IA (Claude Code, Claude Desktop, ou tout client MCP compatible).

## Démarrage rapide

### En local avec Docker

```bash
docker compose run --rm -T app mix mcp.server
```

### Sans Docker

```bash
MIX_ENV=dev mix mcp.server
```

> Le flag `-T` est indispensable avec Docker pour que stdin/stdout soient correctement connectés (transport STDIO).

## Configuration Claude Code

Ajouter dans `.claude/settings.json` ou le fichier de configuration MCP :

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

## Configuration Claude Desktop

Ajouter dans `claude_desktop_config.json` :

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

## Prérequis

- La base de données doit être accessible (Docker Compose démarré)
- Au moins un utilisateur admin doit exister en base (sinon les opérations d'écriture échoueront)

## Tools disponibles (29)

### Utilisateurs

| Tool | Description | Exemple d'usage |
|------|-------------|-----------------|
| `list_users` | Lister les utilisateurs (all/pending/validated) | "Montre-moi les utilisateurs en attente de validation" |
| `search_users` | Rechercher par pseudo ou email | "Cherche l'utilisateur pierre@example.com" |
| `validate_user` | Valider un utilisateur | "Valide l'utilisateur #42" |
| `invalidate_user` | Révoquer la validation | "Révoque la validation de l'utilisateur #42" |

**Exemple de conversation :**
```
Utilisateur : Combien d'utilisateurs sont en attente de validation ?
Claude : [appelle list_users avec filter="pending"]
→ 3 utilisateurs en attente : Pierre (id: 12), Marie (id: 15), Jean (id: 18)

Utilisateur : Valide Pierre et Marie
Claude : [appelle validate_user pour id 12, puis id 15]
→ Pierre et Marie ont été validés avec succès.
```

### Radeaux

| Tool | Description | Exemple d'usage |
|------|-------------|-----------------|
| `list_rafts` | Lister les radeaux (filtrer par statut/nom) | "Liste tous les radeaux proposés" |
| `get_raft` | Détails d'un radeau (équipage, liens) | "Donne-moi les détails du radeau #3" |
| `validate_raft` | Valider un radeau | "Valide le radeau Le Minou Aquatique" |
| `invalidate_raft` | Invalider un radeau | "Invalide le radeau #5" |

**Exemple de conversation :**
```
Utilisateur : Quels radeaux n'ont pas encore été validés ?
Claude : [appelle list_rafts avec status="proposed"]
→ 2 radeaux proposés :
  - "Le Minou Aquatique" (id: 3, 4 membres)
  - "Les Sardines Volantes" (id: 7, 2 membres)

Utilisateur : Valide Le Minou Aquatique
Claude : [appelle validate_raft avec raft_id=3]
→ Le radeau "Le Minou Aquatique" a été validé.
```

### Équipage

| Tool | Description | Exemple d'usage |
|------|-------------|-----------------|
| `list_crew_members` | Lister les membres d'un équipage | "Qui est dans l'équipage #5 ?" |
| `promote_manager` | Promouvoir en gestionnaire | "Fais de Marie une gestionnaire du crew #5" |
| `demote_manager` | Rétrograder un gestionnaire | "Retire le rôle gestionnaire de Pierre" |
| `set_captain` | Nommer un capitaine | "Nomme Jean capitaine du crew #5" |
| `remove_crew_member` | Retirer un membre | "Retire Pierre du crew #5" |

### Demandes d'embarquement

| Tool | Description | Exemple d'usage |
|------|-------------|-----------------|
| `list_join_requests` | Demandes en attente pour un équipage | "Y a-t-il des demandes en attente pour le crew #3 ?" |
| `accept_join_request` | Accepter une demande | "Accepte la demande #12" |
| `reject_join_request` | Refuser une demande | "Refuse la demande #12" |

### Fiches d'inscription

| Tool | Description | Exemple d'usage |
|------|-------------|-----------------|
| `list_registration_forms` | Lister les fiches (filtrer par statut/radeau) | "Quelles fiches sont en attente ?" |
| `approve_registration_form` | Approuver une fiche | "Approuve la fiche #8" |
| `reject_registration_form` | Rejeter avec un motif | "Rejette la fiche #8 : photo illisible" |

**Exemple de conversation :**
```
Utilisateur : Quelles fiches d'inscription sont en attente de validation ?
Claude : [appelle list_registration_forms avec status="pending"]
→ 5 fiches en attente. Voulez-vous les détails ?

Utilisateur : Approuve celles du radeau Le Minou Aquatique
Claude : [appelle list_registration_forms avec status="pending", raft_id=3]
→ 2 fiches trouvées pour ce radeau (id: 14, 15)
[appelle approve_registration_form pour chaque]
→ Les 2 fiches ont été approuvées.
```

### Bidons

| Tool | Description | Exemple d'usage |
|------|-------------|-----------------|
| `list_drum_requests` | Lister les commandes (all/pending/paid) | "Quelles commandes de bidons sont impayées ?" |
| `validate_drum_payment` | Valider un paiement | "Marque la commande #6 comme payée" |
| `update_drum_settings` | Modifier les paramètres (prix, RIB) | "Change le prix du bidon à 15 euros" |

### CUF (Cotisation Urbaine Flottante)

| Tool | Description | Exemple d'usage |
|------|-------------|-----------------|
| `list_cuf_declarations` | Lister les déclarations (all/pending/validated) | "Quelles déclarations CUF sont en attente ?" |
| `validate_cuf_declaration` | Valider une déclaration | "Valide la déclaration CUF #4" |
| `update_cuf_settings` | Modifier les paramètres (prix, limite, RIB) | "Fixe la CUF à 20 euros par personne" |

### Équipes transverses

| Tool | Description | Exemple d'usage |
|------|-------------|-----------------|
| `list_transverse_teams` | Lister les équipes | "Quelles équipes transverses existent ?" |
| `create_transverse_team` | Créer une équipe | "Crée une équipe sécurité" |
| `add_team_member` | Ajouter un membre | "Ajoute Marie à l'équipe accueil" |
| `remove_team_member` | Retirer un membre | "Retire Pierre de l'équipe sécurité" |

## Resources disponibles (6)

Les resources fournissent des vues d'ensemble en lecture seule, utiles pour le contexte.

| URI | Description |
|-----|-------------|
| `ho-mon-radeau://edition/current` | Infos de l'édition en cours (dates, nom) |
| `ho-mon-radeau://users/summary` | Stats utilisateurs (total, validés, en attente) |
| `ho-mon-radeau://rafts/overview` | Liste des radeaux avec statut et nombre de membres |
| `ho-mon-radeau://forms/stats` | Stats fiches d'inscription par radeau |
| `ho-mon-radeau://drums/summary` | Résumé commandes de bidons + paramètres |
| `ho-mon-radeau://cuf/stats` | Stats CUF (participants validés, limite) |

## Architecture technique

```
lib/ho_mon_radeau/mcp/
  server.ex     # Module principal : 29 deftool + 6 defresource + handlers
  helpers.ex    # Sérialisation JSON + get_system_admin/0

lib/mix/tasks/
  mcp.server.ex # Entrypoint : mix mcp.server
```

- **Librairie** : `ex_mcp ~> 0.8`
- **Transport** : STDIO (JSON-RPC sur stdin/stdout)
- **Authentification** : implicite (accès local via STDIO = admin)
- **Admin système** : le premier `%User{is_admin: true}` en base est utilisé pour les opérations d'écriture

## Scénarios d'administration type

### Onboarding de nouveaux participants
```
"Montre-moi les utilisateurs en attente de validation"
"Valide tous ceux qui ont un prénom et un nom renseignés"
```

### Suivi financier
```
"Fais-moi un résumé des paiements : bidons impayés et CUF en attente"
"Valide toutes les commandes de bidons marquées comme payées par virement"
```

### Préparation de l'événement
```
"Quels radeaux n'ont pas encore tous leurs membres avec une fiche validée ?"
"Liste les équipages sans capitaine"
```
