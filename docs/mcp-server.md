# Serveur MCP — Administration HoMonRadeau

Serveur [Model Context Protocol](https://modelcontextprotocol.io/) permettant d'administrer l'événement Tutto Blu via un outil IA (Claude Code, Claude Desktop, ou tout client MCP compatible).

## Mode HTTP (production)

Le serveur MCP est accessible via l'endpoint HTTP de l'app Phoenix, authentifié par token API personnel.

**URL** : `https://ho-mon-radeau.fly.dev/api/mcp`

### 1. Créer un token API

Allez sur votre profil (`/mon-profil`), section "Tokens API (MCP)" en bas de page (visible uniquement pour les admins). Créez un token avec un label descriptif. **Copiez-le immédiatement** — il ne sera plus visible ensuite.

### 2. Configurer votre outil IA

#### Claude Desktop

Note : "type": "sse" a été ajouté suite à test avec Claude code. Le type "streamable-http" ne fonctionnait pas. Il est possible qu'il ne corresponde pas à d'autres outils.

```json
{
  "mcpServers": {
    "ho-mon-radeau": {
      "url": "https://ho-mon-radeau.fly.dev/mcp",
      "type": "sse",
      "headers": {
        "Authorization": "Bearer VOTRE_TOKEN"
      }
    }
  }
}
```

#### ChatGPT (Custom GPT / Actions)

Dans la configuration d'un Custom GPT, ajoutez une Action :

- **URL** : `https://ho-mon-radeau.fly.dev/api/mcp`
- **Authentification** : API Key
- **Header** : `Authorization: Bearer VOTRE_TOKEN`

#### Autre outil MCP

Tout client compatible MCP peut se connecter via HTTP avec l'URL et le header `Authorization: Bearer VOTRE_TOKEN`.

## Mode STDIO (développement local)

Pour le développement, le serveur peut tourner en local via stdin/stdout. Un fichier d'exemple `exemple.mcp.json` est fourni à la racine du projet.

```bash
# Démarrer le serveur MCP en local
docker compose run --rm -T app mix mcp.server
```

> Le flag `-T` est indispensable avec Docker pour que stdin/stdout soient correctement connectés.

### Configuration Claude Code (local)

Copier `exemple.mcp.json` et adapter le chemin :

```bash
cp exemple.mcp.json .mcp.json
# Éditer .mcp.json pour ajuster le chemin "cwd"
```

Ou ajouter manuellement dans `.claude/settings.json` :

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

### Configuration Claude Desktop (local)

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

- **Mode HTTP (prod)** : un compte admin avec un token API créé depuis le profil
- **Mode STDIO (local)** : Docker Compose démarré, au moins un admin en base

## Authentification

Chaque admin génère ses propres tokens API depuis sa page profil (`/mon-profil`). Les tokens sont :

- **Personnels** : chaque token est lié à un utilisateur
- **Hashés en base** : le token brut n'est montré qu'une fois à la création
- **Révocables** : un token peut être révoqué depuis le profil
- **Tracés** : `last_used_at` est mis à jour à chaque utilisation
- **Restreints aux admins** : seuls les utilisateurs `is_admin` peuvent accéder au MCP via HTTP

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
  server.ex                    # 29 deftool + 6 defresource + handlers
  helpers.ex                   # Sérialisation + get_current_admin/0

lib/ho_mon_radeau/accounts/
  api_token.ex                 # Schema tokens API (hashés, révocables)

lib/ho_mon_radeau_web/
  controllers/mcp_controller.ex  # Endpoint HTTP avec auth Bearer
  plugs/api_auth.ex              # Plug d'authentification API (réutilisable)

lib/mix/tasks/
  mcp.server.ex                # Entrypoint STDIO : mix mcp.server
```

- **Librairie** : `ex_mcp ~> 0.8`
- **Transport HTTP** : `POST /api/mcp` via Phoenix + ExMCP.HttpPlug
- **Transport STDIO** : `mix mcp.server` pour usage local
- **Auth HTTP** : Bearer token personnel, vérifié + user chargé + check admin
- **Auth STDIO** : implicite (accès local = premier admin en base)

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
