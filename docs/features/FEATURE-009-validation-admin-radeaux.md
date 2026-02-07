# FEATURE-009 : Validation admin des radeaux

## Description
Les administrateurs peuvent valider ou invalider les radeaux créés par les utilisateurs. Un radeau validé obtient le statut "Participant" et apparaît en priorité dans les listes. La validation permet aux organisateurs de contrôler quels radeaux participeront effectivement à l'événement.

## Objectif
Maintenir un contrôle organisationnel sur les radeaux participants en permettant aux administrateurs de valider les équipages qui répondent aux critères de participation (équipage complet, construction avancée, engagement confirmé). Distinguer clairement les radeaux participants des radeaux en cours de formation.

## Utilisateurs concernés
- **Administrateurs** : Valident ou invalident les radeaux
- **Équipages** : Voient le statut de leur radeau et aspirent à être validés
- **Visiteurs** : Voient la distinction entre radeaux participants et proposés

## Comportement attendu

### Statuts des radeaux

#### Radeau "Proposé" (non validé)
- Statut par défaut lors de la création
- Badge "Proposé" affiché sur les pages publiques et privées
- Apparaît dans la liste des radeaux, **après les participants**
- L'équipage peut fonctionner normalement (membres, rôles, bidons, CUF)

#### Radeau "Participant" (validé)
- Validé par un administrateur
- Badge "Participant" affiché sur les pages publiques et privées
- Apparaît **en premier** dans la liste des radeaux
- Représente un engagement confirmé de participation à l'événement

### Validation par un administrateur

#### Depuis la page admin
1. Liste de tous les radeaux avec leur statut
2. Colonnes : Nom, Statut, Nombre de membres, Date de création, Actions
3. Bouton "Valider" pour les radeaux proposés
4. Bouton "Invalider" pour les radeaux participants

#### Confirmation
```
Valider le radeau [NOM]

Ce radeau passera au statut "Participant" et apparaîtra
en priorité dans la liste des radeaux.

[Confirmer] [Annuler]
```

#### Traçabilité
- Date de validation enregistrée
- Administrateur ayant validé enregistré
- Historique consultable (optionnel)

### Affichage du statut

#### Page publique du radeau
```
RADEAU LA LOUTRE
[Badge: Participant] ou [Badge: Proposé]
```

#### Page privée du radeau
```
RADEAU LA LOUTRE
[Badge: Participant ✓]

ou

RADEAU LA LOUTRE
[Badge: Proposé]
ℹ️ Votre radeau est en cours de validation par l'organisation.
```

#### Liste des radeaux
Les radeaux sont classés par statut :
```
PARTICIPANTS (12 radeaux)
[Liste des radeaux validés]

PROPOSÉS (5 radeaux)
[Liste des radeaux non validés]
```

### Recherche multi-critères (admin)

#### Page admin avec filtres
- **Nom** : Recherche textuelle
- **Statut** : Participant / Proposé
- **Équipage complet** : Oui / Non (à définir : critère de complétude)
- **CUF payée** : Oui / Non / Partielle
- **Nombre d'équipiers** : Min / Max
- **Bidons** : Demandés / Payés / Aucun

#### Résultats
Tableau avec colonnes triables :
- Nom du radeau
- Statut (badge)
- Membres (nombre)
- CUF (statut)
- Bidons (nombre + paiement)
- Date de création
- Actions (Valider / Invalider / Voir détails)

## Règles métier

### Validation
- Seuls les **administrateurs** peuvent valider/invalider
- La validation est **réversible** (un radeau validé peut être invalidé)
- Pas de critères techniques automatiques (tout est manuel)
- La validation n'empêche pas le fonctionnement du radeau (un radeau proposé peut avoir des membres, bidons, CUF)

### Impact de la validation
**Impact actuel :**
- Badge visuel différent
- Ordre d'affichage dans les listes (participants en premier)
- Filtre possible dans la recherche

**Pas d'impact sur :**
- Fonctionnement interne de l'équipage
- Possibilité de recruter des membres
- Gestion des bidons et CUF

**Impact futur potentiel (à discuter) :**
- Accès à certaines ressources
- Validation de participation effective à l'événement
- Priorité sur les bidons si stock limité

### Critères de validation (informels)
Critères laissés à l'appréciation des administrateurs :
- Équipage suffisamment constitué
- Rôles clés attribués (capitaine, etc.)
- Engagement confirmé de participation
- Construction du radeau avancée
- CUF payée ou en cours

### Nombre de radeaux
- Moins de 50 radeaux sur l'événement
- Donc gestion manuelle acceptable

## Interface utilisateur

### Page admin - Liste des radeaux
```
Administration - Radeaux

Recherche et filtres
--------------------
Nom : [___________]
Statut : [Tous ▼] [Participants] [Proposés]
Équipage complet : [Tous ▼]
CUF payée : [Tous ▼]
Nombre d'équipiers : [Min __] [Max __]

[Rechercher] [Réinitialiser]

Résultats (17 radeaux)
----------------------
| Nom          | Statut      | Membres | CUF    | Bidons | Créé le    | Actions      |
|--------------|-------------|---------|--------|--------|------------|--------------|
| La Loutre    | Participant | 15      | Payée  | 80 (✓) | 01/01/2025 | [Invalider] [Voir] |
| Le Kraken    | Proposé     | 8       | Non    | 0      | 15/01/2025 | [Valider] [Voir]   |
| L'Albatros   | Proposé     | 3       | Non    | 40 (⏳) | 20/01/2025 | [Valider] [Voir]   |
```

### Modal de confirmation validation
```
┌────────────────────────────────────────┐
│ Valider le radeau "Le Kraken"          │
│                                        │
│ Ce radeau passera au statut           │
│ "Participant" et apparaîtra en        │
│ priorité dans la liste des radeaux.   │
│                                        │
│ [Confirmer la validation] [Annuler]   │
└────────────────────────────────────────┘
```

### Badge sur les pages
```css
/* Participant */
[Participant ✓]
/* Badge vert */

/* Proposé */
[Proposé]
/* Badge gris/bleu */
```

## Dépendances
- **FEATURE-003** (Création équipage) : Champ `validated` sur les radeaux
- **FEATURE-007** (Pages publiques) : Affichage du badge et tri
- **FEATURE-008** (Pages privées) : Affichage du statut
- **FEATURE-011** (Bidons) : Critère de recherche
- **FEATURE-012** (CUF) : Critère de recherche

## Notes techniques

### Implémentation

#### Base de données
Champs existants dans `rafts` :
```elixir
create table :rafts do
  # ...
  add :validated, :boolean, default: false
  add :validated_at, :datetime
  add :validated_by_id, references(:users)
end

create index(:rafts, [:validated])
```

#### Routes admin
```elixir
scope "/admin", HoMonRadeauWeb.Admin, as: :admin do
  pipe_through [:browser, :require_authenticated_user, :require_admin]

  get "/radeaux", RaftController, :index
  post "/radeaux/:id/validate", RaftController, :validate
  post "/radeaux/:id/invalidate", RaftController, :invalidate
end
```

#### Controller admin
```elixir
defmodule HoMonRadeauWeb.Admin.RaftController do
  def index(conn, params) do
    # Appliquer les filtres de recherche
    rafts = Events.search_rafts(params)

    render(conn, "index.html", rafts: rafts, params: params)
  end

  def validate(conn, %{"id" => id}) do
    raft = Events.get_raft!(id)
    admin = conn.assigns.current_user

    case Events.validate_raft(raft, admin) do
      {:ok, _raft} ->
        conn
        |> put_flash(:info, "Radeau validé avec succès.")
        |> redirect(to: Routes.admin_raft_path(conn, :index))

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Erreur lors de la validation.")
        |> redirect(to: Routes.admin_raft_path(conn, :index))
    end
  end

  def invalidate(conn, %{"id" => id}) do
    raft = Events.get_raft!(id)

    case Events.invalidate_raft(raft) do
      {:ok, _raft} ->
        conn
        |> put_flash(:info, "Radeau invalidé.")
        |> redirect(to: Routes.admin_raft_path(conn, :index))

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Erreur lors de l'invalidation.")
        |> redirect(to: Routes.admin_raft_path(conn, :index))
    end
  end
end
```

#### Contexte
```elixir
defmodule HoMonRadeau.Events do
  def validate_raft(raft, admin) do
    raft
    |> Raft.changeset(%{
      validated: true,
      validated_at: DateTime.utc_now(),
      validated_by_id: admin.id
    })
    |> Repo.update()
  end

  def invalidate_raft(raft) do
    raft
    |> Raft.changeset(%{
      validated: false,
      validated_at: nil,
      validated_by_id: nil
    })
    |> Repo.update()
  end

  def search_rafts(params) do
    base_query = from(r in Raft,
      left_join: c in Crew, on: c.raft_id == r.id,
      left_join: cm in CrewMember, on: cm.crew_id == c.id,
      group_by: r.id,
      select: %{
        raft: r,
        member_count: count(cm.id)
      }
    )

    base_query
    |> filter_by_name(params["name"])
    |> filter_by_status(params["status"])
    |> filter_by_member_count(params["min_members"], params["max_members"])
    |> order_by([r], [desc: r.validated, asc: r.name])
    |> Repo.all()
  end

  defp filter_by_name(query, nil), do: query
  defp filter_by_name(query, ""), do: query
  defp filter_by_name(query, name) do
    from [r] in query,
      where: ilike(r.name, ^"%#{name}%")
  end

  defp filter_by_status(query, "validated"), do: where(query, [r], r.validated == true)
  defp filter_by_status(query, "proposed"), do: where(query, [r], r.validated == false)
  defp filter_by_status(query, _), do: query

  defp filter_by_member_count(query, nil, nil), do: query
  defp filter_by_member_count(query, min, max) do
    query = if min, do: having(query, [r, c, cm], count(cm.id) >= ^min), else: query
    query = if max, do: having(query, [r, c, cm], count(cm.id) <= ^max), else: query
    query
  end
end
```

#### Permissions
```elixir
defmodule HoMonRadeauWeb.Plugs.RequireAdmin do
  def init(opts), do: opts

  def call(conn, _opts) do
    user = conn.assigns.current_user

    if user.is_admin do
      conn
    else
      conn
      |> put_flash(:error, "Accès réservé aux administrateurs.")
      |> redirect(to: Routes.page_path(conn, :index))
      |> halt()
    end
  end
end
```

### Sécurité
- Vérifier les permissions admin avant toute action
- Logger les validations/invalidations (qui, quand, quel radeau)
- Audit trail des changements de statut

### Performance
- Index sur `rafts.validated` pour filtrer rapidement
- Optimiser les requêtes de recherche avec les filtres
- Pagination si le nombre de radeaux augmente

### UX
- Badge visuel clair et différencié
- Confirmation avant validation/invalidation
- Message informatif pour les équipages proposés
- Tri automatique (participants en premier) dans toutes les listes
- Filtres simples et intuitifs dans la page admin
