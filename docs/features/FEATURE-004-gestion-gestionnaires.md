# FEATURE-004 : Gestion des gestionnaires d'équipage

## Description
Permet aux gestionnaires d'un équipage de nommer d'autres membres comme gestionnaires, et de retirer ce statut si nécessaire. Les gestionnaires ont tous les mêmes droits sur l'équipage, sans hiérarchie entre eux.

## Objectif
Permettre une gestion collaborative et horizontale des équipages en donnant la possibilité de partager les responsabilités de gestion entre plusieurs membres. Cela évite la dépendance à une seule personne et favorise l'autonomie collective.

## Utilisateurs concernés
- **Gestionnaires actuels** : Peuvent nommer ou retirer d'autres gestionnaires
- **Membres de l'équipage** : Peuvent être promus gestionnaires
- **Administrateurs** : Peuvent intervenir en cas de problème (équipage sans gestionnaire)

## Comportement attendu

### Droits des gestionnaires
Tous les gestionnaires ont exactement les mêmes droits :
- Nommer de nouveaux gestionnaires
- Retirer le statut gestionnaire à d'autres gestionnaires
- Ajouter/retirer des membres de l'équipage
- Modifier les informations du radeau (nom, description, photo, etc.)
- Gérer les demandes d'adhésion
- Attribuer les rôles (capitaine, lead construction, etc.)

### Nomination d'un gestionnaire
1. Gestionnaire accède à la page privée du radeau
2. Dans la liste des membres, bouton "Nommer gestionnaire" à côté d'un membre
3. Confirmation : "Voulez-vous nommer [PSEUDO] comme gestionnaire ?"
4. Une fois confirmé, le membre devient gestionnaire immédiatement

### Retrait du statut gestionnaire
1. Gestionnaire accède à la liste des gestionnaires
2. Bouton "Retirer" à côté d'un gestionnaire (sauf soi-même)
3. Confirmation : "Voulez-vous retirer le statut gestionnaire à [PSEUDO] ?"
4. Le membre perd immédiatement le statut gestionnaire

### Cas particuliers

#### Créateur initial
- Le créateur du radeau est le premier gestionnaire
- Il a exactement les mêmes droits que les autres gestionnaires
- Il peut se retirer lui-même du statut gestionnaire
- Il peut même quitter l'équipage complètement

#### Équipage sans gestionnaire
Si tous les gestionnaires quittent l'équipage ou retirent leur statut :
- **Pas de promotion automatique**
- **Un administrateur peut promouvoir un membre** en gestionnaire
- Message d'alerte visible pour les admins : "Équipage [NOM] sans gestionnaire"

#### Auto-retrait
- Un gestionnaire peut se retirer lui-même
- Si c'est le dernier gestionnaire, confirmation renforcée : "Attention : vous êtes le dernier gestionnaire. L'équipage n'aura plus de gestionnaire après cette action."

## Règles métier

### Égalité des droits
- **Aucune hiérarchie** entre gestionnaires
- Le créateur n'a pas de privilèges supplémentaires
- Tous les gestionnaires peuvent nommer/retirer d'autres gestionnaires

### Nombre de gestionnaires
- **Pas de limite maximum** de gestionnaires
- **Minimum recommandé : 1** (mais techniquement peut être 0 temporairement)

### Permissions
- Seuls les gestionnaires peuvent modifier le statut gestionnaire
- Les admins peuvent également promouvoir des membres (en cas d'urgence)

### Traçabilité
- Logger toutes les actions : qui a nommé/retiré qui et quand
- Historique consultable par les admins

## Interface utilisateur

### Page privée du radeau - Section Gestionnaires
```
Gestionnaires de l'équipage
---------------------------
[Photo] Pseudo1 (gestionnaire depuis le JJ/MM/AAAA) [Retirer]
[Photo] Pseudo2 (gestionnaire depuis le JJ/MM/AAAA) [Retirer]
[Photo] Vous (gestionnaire depuis le JJ/MM/AAAA) [Me retirer]

Membres de l'équipage
---------------------
[Photo] Pseudo3 [Nommer gestionnaire]
[Photo] Pseudo4 [Nommer gestionnaire]
```

### Confirmations
**Nomination :**
```
Nommer gestionnaire

Voulez-vous nommer [PSEUDO] comme gestionnaire de l'équipage [RADEAU] ?

Cette personne aura les mêmes droits que vous sur l'équipage :
- Gérer les membres
- Gérer les demandes d'adhésion
- Modifier les informations du radeau
- Nommer/retirer d'autres gestionnaires

[Confirmer] [Annuler]
```

**Retrait :**
```
Retirer le statut gestionnaire

Voulez-vous retirer le statut gestionnaire à [PSEUDO] ?

Cette personne restera membre de l'équipage mais n'aura plus les droits de gestion.

[Confirmer] [Annuler]
```

**Auto-retrait (dernier gestionnaire) :**
```
⚠️ Attention

Vous êtes le dernier gestionnaire de cet équipage. Si vous retirez votre statut, l'équipage n'aura plus de gestionnaire et seul un administrateur pourra en nommer un nouveau.

Êtes-vous sûr de vouloir continuer ?

[Oui, me retirer] [Annuler]
```

### Page admin - Équipages sans gestionnaire
```
⚠️ Équipages sans gestionnaire

Radeau [NOM] - Créé le JJ/MM/AAAA - X membres
[Voir l'équipage] [Promouvoir un membre]
```

## Dépendances
- **FEATURE-003** (Création équipage) : Base de la structure gestionnaire
- **FEATURE-005** (Adhésion équipage) : Pour gérer les membres
- **FEATURE-008** (Pages privées) : Interface de gestion

## Notes techniques

### Implémentation

#### Base de données
Le champ `is_manager` existe déjà dans `crew_members` :
```elixir
create table :crew_members do
  add :crew_id, references(:crews), null: false
  add :user_id, references(:users), null: false
  add :is_manager, :boolean, default: false
  # ...
end
```

Ajouter un champ pour la traçabilité :
```elixir
alter table :crew_members do
  add :manager_since, :datetime
  add :promoted_by_id, references(:users)
end
```

#### Contexte Elixir
```elixir
defmodule HoMonRadeau.Events do
  def promote_to_manager(crew, user_id, promoted_by_user_id) do
    crew_member = get_crew_member(crew.id, user_id)

    crew_member
    |> CrewMember.changeset(%{
      is_manager: true,
      manager_since: DateTime.utc_now(),
      promoted_by_id: promoted_by_user_id
    })
    |> Repo.update()
  end

  def remove_manager_status(crew, user_id) do
    crew_member = get_crew_member(crew.id, user_id)

    crew_member
    |> CrewMember.changeset(%{
      is_manager: false,
      manager_since: nil
    })
    |> Repo.update()
  end

  def is_manager?(crew, user) do
    from(cm in CrewMember,
      where: cm.crew_id == ^crew.id and cm.user_id == ^user.id and cm.is_manager == true
    )
    |> Repo.exists?()
  end

  def get_crews_without_managers() do
    # Pour les admins : liste des équipages sans gestionnaire
    from(c in Crew,
      left_join: cm in CrewMember, on: cm.crew_id == c.id and cm.is_manager == true,
      group_by: c.id,
      having: count(cm.id) == 0
    )
    |> Repo.all()
  end
end
```

#### Permissions (Plug)
```elixir
defmodule HoMonRadeauWeb.Plugs.RequireManager do
  def init(opts), do: opts

  def call(conn, _opts) do
    crew_id = conn.params["crew_id"]
    user = conn.assigns.current_user

    if Events.is_manager?(crew_id, user) do
      conn
    else
      conn
      |> put_flash(:error, "Vous devez être gestionnaire pour effectuer cette action.")
      |> redirect(to: Routes.raft_path(conn, :show, crew_id))
      |> halt()
    end
  end
end
```

### Sécurité
- Vérifier que l'utilisateur actuel est gestionnaire avant toute action
- Empêcher le retrait du dernier gestionnaire sans confirmation explicite
- Logger toutes les promotions/retraits pour audit
- Notifications aux autres gestionnaires en cas de changement

### Performance
- Index sur `crew_members.is_manager` pour requêtes rapides
- Cache de la liste des gestionnaires par équipage (optionnel)

### UX
- Confirmations claires pour éviter les erreurs
- Message d'alerte si retrait du dernier gestionnaire
- Notifications aux gestionnaires ajoutés/retirés
- Badge visible "Gestionnaire" sur le profil dans l'équipage
