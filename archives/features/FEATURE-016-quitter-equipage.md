# FEATURE-016 : Quitter un équipage

## Description
Permet à un membre de quitter volontairement son équipage. L'application affiche un avertissement si la personne est impliquée dans une CUF déclarée ou validée. Les gestionnaires de l'équipage et les admins sont notifiés. Un tableau de suivi des départs est accessible aux admins pour faciliter les régularisations CUF.

## Objectif
Permettre la mobilité des participants tout en maintenant la cohérence des données CUF. Éviter les situations où un membre quitte silencieusement et laisse une CUF déséquilibrée sans que l'organisation s'en aperçoive.

## Utilisateurs concernés
- **Membres d'équipage** : peuvent quitter leur équipage
- **Gestionnaires d'équipage** : notifiés d'un départ, peuvent retirer un membre
- **Capitaine** : doit régulariser la CUF après un départ
- **Administrateurs** : accès au tableau de suivi des départs

## Comportement attendu

### Quitter son équipage (membre)

#### Accès
- Bouton "Quitter l'équipage" sur la page privée du radeau (section profil du membre)

#### Workflow standard (sans CUF concernée)
1. Membre clique "Quitter l'équipage"
2. Confirmation : "Voulez-vous vraiment quitter l'équipage [NOM] ?"
3. Confirmation → membre retiré, notification aux gestionnaires
4. Redirection vers la liste des radeaux

#### Workflow avec avertissement (CUF déclarée ou validée)
1. Membre clique "Quitter l'équipage"
2. **Avertissement affiché** :
```
⚠️ Vous êtes déclaré·e comme participant·e dans la CUF de cet équipage.

Si vous quittez, le capitaine devra régulariser la CUF.
Les gestionnaires seront notifiés.

[Quitter quand même] [Annuler]
```
3. Si confirmation → membre retiré, statut CUF devient "CUF restant" négatif, notifications envoyées

#### Cas du dernier gestionnaire
Si le membre est le seul gestionnaire :
```
⚠️ Vous êtes le seul gestionnaire de cet équipage.
Si vous quittez, aucun gestionnaire ne pourra gérer
l'équipage. Un administrateur devra intervenir.

[Quitter quand même] [Annuler]
```

#### Cas du capitaine
Si le membre est le capitaine, avertissement supplémentaire :
```
⚠️ Vous êtes le capitaine de cet équipage.
En quittant, le rôle de capitaine sera retiré.
Un gestionnaire devra nommer un nouveau capitaine.
```

### Retrait d'un membre par un gestionnaire

Un gestionnaire peut retirer un membre depuis la liste des membres (page privée).
Même logique d'avertissement si le membre est concerné par une CUF.

### Après un départ

#### Mises à jour automatiques
- Statut de participation du membre → retiré de l'équipage
- Si le membre était `participant` dans une CUF validée → "CUF restant à régler" devient négatif sur la page de l'équipage
- Si le membre était capitaine → rôle capitaine retiré, équipage sans capitaine
- Si le membre était le seul gestionnaire → équipage sans gestionnaire (alerte admin)

#### Enregistrement du départ
Chaque départ est enregistré dans une table `crew_departures` avec :
- Qui a quitté
- De quel équipage
- Quand
- Statut CUF au moment du départ (`none`, `declared`, `validated`)
- Si retiré par un gestionnaire (vs départ volontaire)

## Notifications

### Gestionnaires de l'équipage
Email + notification in-app :
> "[PSEUDO] a quitté l'équipage [NOM DU RADEAU]."
> Si CUF concernée : "Vous devrez régulariser la CUF (1 participant en moins)."

### Administrateurs (tableau de suivi)
Pas de notification individuelle — accès au tableau de bord des départs (voir ci-dessous).

## Tableau de suivi des départs (admin)

Accessible uniquement aux admins, à `/admin/departures` ou dans le dashboard admin.

### Colonnes
| Membre | Équipage | Date départ | Statut CUF au départ | Régularisé |
|--------|----------|-------------|----------------------|------------|
| @pseudo | La Loutre | 15/01/2026 | CUF validée | ⏳ En attente |
| @pseudo2 | Le Kraken | 10/01/2026 | Aucune CUF | ✓ |

### Filtres
- Par équipage
- Par statut CUF au départ
- Par date

### Objectif
Permettre aux organisateurs de suivre facilement les départs ayant un impact sur la CUF et de s'assurer que les capitaines régularisent. Pas d'action depuis ce tableau — c'est un outil de suivi uniquement.

## Règles métier

### Qui peut quitter ?
- Tout membre peut quitter son équipage à tout moment
- Pas de blocage si CUF validée (avertissement seulement)

### Statut CUF après départ
- Si membre `en attente` (non déclaré CUF) → pas d'impact CUF
- Si membre `participant` (CUF déclarée ou validée) → "CUF restant à régler" passe à négatif
- La régularisation (nouvelle déclaration CUF) est à la charge du capitaine

### Après le départ
- L'utilisateur redevient libre de rejoindre ou créer un autre équipage
- Ses demandes d'adhésion en attente à d'autres radeaux ne sont pas rétablies automatiquement
- L'historique de son appartenance est conservé (table `crew_departures`)

## Interface utilisateur

### Bouton "Quitter" (page privée, section membre)
```
Mon profil dans l'équipage
--------------------------
Rôles : Cuisine, Interlocuteur SAFE
[Modifier mes rôles]

[Quitter cet équipage]  ← en rouge, discret
```

### Page de confirmation (cas standard)
```
Quitter l'équipage La Loutre

Vous vous apprêtez à quitter cet équipage.
Cette action est immédiate.

[Confirmer] [Annuler]
```

### Page de confirmation (avec avertissement CUF)
```
Quitter l'équipage La Loutre

⚠️ Vous êtes déclaré·e comme participant·e dans la
cotisation (CUF) de cet équipage.

En quittant, le capitaine devra régulariser la CUF.
Les gestionnaires seront notifiés de votre départ.

[Quitter quand même] [Annuler]
```

## Dépendances
- **FEATURE-005** (Adhésion) : Structure crew_members
- **FEATURE-012** (CUF) : Statut participation + régularisation
- **FEATURE-006** (Rôles) : Retrait du rôle capitaine si applicable
- **FEATURE-004** (Gestionnaires) : Alerte si dernier gestionnaire
- **FEATURE-014** (Admin) : Tableau de suivi dans l'interface admin

## Notes techniques

### Base de données

#### Nouvelle table `crew_departures`
```elixir
create table :crew_departures do
  add :user_id, references(:users), null: false
  add :crew_id, references(:crews), null: false
  add :removed_by_id, references(:users)  # nil si départ volontaire
  add :cuf_status_at_departure, :string   # none | declared | validated
  add :was_captain, :boolean, default: false
  add :was_manager, :boolean, default: false

  timestamps()
end

create index(:crew_departures, [:crew_id])
create index(:crew_departures, [:user_id])
create index(:crew_departures, [:inserted_at])
```

### Contexte Elixir
```elixir
defmodule HoMonRadeau.Events do
  def leave_crew(user, crew) do
    crew_member = get_crew_member!(crew.id, user.id)
    cuf_status = CUF.get_member_cuf_status(user, crew)

    Multi.new()
    |> Multi.delete(:crew_member, crew_member)
    |> Multi.insert(:departure, %CrewDeparture{
      user_id: user.id,
      crew_id: crew.id,
      cuf_status_at_departure: cuf_status,
      was_captain: crew_member.is_captain,
      was_manager: crew_member.is_manager
    })
    |> Repo.transaction()
  end

  def has_cuf_impact?(user, crew) do
    member = get_crew_member(crew.id, user.id)
    member && member.participation_status in ["pending_validation", "participant"]
  end
end
```

### Sécurité
- Vérifier que l'utilisateur quitte son propre équipage (ou que c'est un gestionnaire qui retire un membre)
- Logger tous les départs (table `crew_departures`)
- Pas de suppression de l'historique

### UX
- Avertissement CUF visible et explicite
- Double confirmation si CUF concernée
- Redirection claire après départ
- Pas de départ "silencieux" — toujours une confirmation
