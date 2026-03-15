# FEATURE-005 : Adhésion à un équipage

## Description
Permet aux utilisateurs de rejoindre un équipage, soit par ajout direct d'un gestionnaire, soit en faisant une demande d'adhésion qui devra être validée par un gestionnaire. Les utilisateurs non validés peuvent voir leur demande affichée mais ne peuvent pas être ajoutés.

## Objectif
Faciliter la formation des équipages en permettant deux modes complémentaires : l'invitation directe (pour les personnes connues) et la candidature spontanée (pour les personnes cherchant un radeau). Tout en maintenant le contrôle via la validation des gestionnaires.

## Utilisateurs concernés
- **Utilisateurs validés** : Peuvent faire une demande d'adhésion ou être ajoutés directement
- **Utilisateurs non validés** : Peuvent faire une demande (affichée) mais ne peuvent pas être ajoutés
- **Gestionnaires d'équipage** : Peuvent ajouter des membres directement et valider les demandes
- **Membres d'équipe bidon, admin** : Peuvent modifier les demandes de bidons

## Comportement attendu

### Mode 1 : Ajout direct par un gestionnaire

#### Pour le gestionnaire
1. Accède à la page privée du radeau
2. Bouton "Ajouter un membre"
3. Formulaire de recherche d'utilisateur (par pseudo, email)
4. Sélection d'un utilisateur validé
5. Confirmation et ajout immédiat

#### Restrictions
- **Utilisateur non validé ne peut PAS être ajouté** directement
- Message d'erreur : "Cet utilisateur doit d'abord être validé par l'équipe d'accueil."
- L'utilisateur doit être validé (FEATURE-002)

### Mode 2 : Demande d'adhésion par un utilisateur

#### Pour l'utilisateur
1. Consulte la liste des radeaux
2. Clique sur un radeau qui l'intéresse
3. Bouton "Demander à rejoindre cet équipage" sur la page publique
4. Formulaire optionnel : message de motivation (optionnel)
5. Confirmation : "Votre demande a été envoyée aux gestionnaires de [RADEAU]"

#### Statut de la demande
- **Utilisateur validé :** Demande visible par les gestionnaires, peut être acceptée
- **Utilisateur non validé :** Demande visible mais marquée "En attente de validation utilisateur"

### Validation de la demande par un gestionnaire

#### Liste des demandes
Les gestionnaires voient la liste des demandes sur la page privée :
```
Demandes d'adhésion (3)
-----------------------
[Photo] Pseudo1 (validé) - Il y a 2 jours
"Message de motivation..."
[Accepter] [Refuser]

[Photo] Pseudo2 (non validé) - Il y a 1 semaine
"Message de motivation..."
⚠️ Cet utilisateur doit d'abord être validé par l'équipe d'accueil
[Refuser]

[Photo] Pseudo3 (validé) - Il y a 3 heures
Pas de message
[Accepter] [Refuser]
```

#### Actions
- **Accepter** : L'utilisateur devient membre de l'équipage, notification envoyée
- **Refuser** : La demande est supprimée, notification envoyée (optionnelle)

### Après adhésion

#### Pour l'utilisateur
1. Notification : "Vous êtes maintenant membre de l'équipage [RADEAU] !"
2. Redirection automatique vers la page privée du radeau lors de la connexion
3. Accès à toutes les fonctionnalités privées de l'équipage

#### Pour l'équipage
1. Le nouveau membre apparaît dans la liste des membres
2. Statut initial : "Membre" (pas gestionnaire, pas de rôle spécifique)

## Règles métier

### Validation utilisateur
- **Utilisateur validé :** Peut être ajouté directement ou via demande acceptée
- **Utilisateur non validé :**
  - Peut faire une demande (visible)
  - Ne peut PAS être ajouté tant qu'il n'est pas validé
  - Sa demande reste en attente avec indication claire

### Unicité
- Un utilisateur ne peut être membre que d'**un seul équipage** à la fois
- Si déjà membre, bouton "Rejoindre" remplacé par "Vous êtes déjà membre d'un équipage"

### Demandes multiples
- Un utilisateur peut faire une demande à **plusieurs radeaux** en même temps
- Si accepté dans un radeau, les autres demandes sont automatiquement annulées

### Permissions
- **Gestionnaires :** Ajout direct + validation des demandes
- **Membres équipe bidons :** Peuvent modifier les demandes de bidons (pas d'ajout de membres)
- **Admins :** Peuvent ajouter n'importe qui à n'importe quel équipage

## Interface utilisateur

### Page publique du radeau
```
Radeau [NOM]
------------
Description...

Membres : 12/20

[Demander à rejoindre cet équipage]
ou
[Vous êtes membre de ce radeau] (si déjà membre)
ou
[Vous êtes déjà membre d'un autre équipage] (si membre ailleurs)
```

### Formulaire de demande
```
Demander à rejoindre [RADEAU]

Message de motivation (optionnel)
[___________________________]
[___________________________]
[___________________________]

[Envoyer ma demande] [Annuler]
```

### Page privée - Section ajout membre (gestionnaire)
```
Ajouter un membre
-----------------
Rechercher un utilisateur
[_________________] [Rechercher]

Résultats :
- [Photo] Pseudo1 (validé) [Ajouter]
- [Photo] Pseudo2 (non validé) ⚠️ Doit être validé
```

### Page privée - Demandes d'adhésion
```
Demandes en attente (3)

[Photo] Pseudo - Il y a X jours
Statut : Utilisateur validé ✓
"Message de motivation..."
[Accepter] [Refuser]

[Photo] Pseudo - Il y a X jours
Statut : ⚠️ En attente de validation utilisateur
"Message de motivation..."
[Refuser]
```

### Notifications
- "Vous êtes maintenant membre de l'équipage [RADEAU] !"
- "Votre demande pour rejoindre [RADEAU] a été refusée."
- "[PSEUDO] a rejoint votre équipage." (pour les gestionnaires)

## Dépendances
- **FEATURE-001** (Inscription) : Base utilisateur
- **FEATURE-002** (Validation nouveaux) : Vérification du statut de validation
- **FEATURE-003** (Création équipage) : Structure de l'équipage
- **FEATURE-004** (Gestionnaires) : Permissions pour validation
- **FEATURE-007** (Pages publiques) : Bouton de demande d'adhésion

## Notes techniques

### Implémentation

#### Base de données
Tables existantes :
```elixir
# crew_members (déjà défini)
# Ajouter les demandes d'adhésion

create table :crew_join_requests do
  add :crew_id, references(:crews), null: false
  add :user_id, references(:users), null: false
  add :message, :text
  add :status, :string, default: "pending" # pending, accepted, rejected

  timestamps()
end

create unique_index(:crew_join_requests, [:crew_id, :user_id])
create index(:crew_join_requests, [:status])
```

#### Contexte Elixir
```elixir
defmodule HoMonRadeau.Events do
  def create_join_request(crew, user, message \\ nil) do
    # Vérifier que l'user n'est pas déjà membre d'un équipage
    case get_user_crew(user) do
      nil ->
        %CrewJoinRequest{}
        |> CrewJoinRequest.changeset(%{
          crew_id: crew.id,
          user_id: user.id,
          message: message,
          status: "pending"
        })
        |> Repo.insert()

      _crew ->
        {:error, :already_in_crew}
    end
  end

  def accept_join_request(request, accepted_by_user) do
    Multi.new()
    |> Multi.update(:request, CrewJoinRequest.changeset(request, %{status: "accepted"}))
    |> Multi.insert(:crew_member, %CrewMember{
      crew_id: request.crew_id,
      user_id: request.user_id,
      is_manager: false
    })
    |> Multi.run(:cancel_other_requests, fn _repo, %{request: _} ->
      # Annuler les autres demandes de cet utilisateur
      from(cjr in CrewJoinRequest,
        where: cjr.user_id == ^request.user_id and cjr.id != ^request.id and cjr.status == "pending"
      )
      |> Repo.update_all(set: [status: "cancelled"])

      {:ok, :cancelled}
    end)
    |> Repo.transaction()
  end

  def reject_join_request(request) do
    request
    |> CrewJoinRequest.changeset(%{status: "rejected"})
    |> Repo.update()
  end

  def add_member_directly(crew, user_id, added_by_user) do
    # Vérifier que l'user est validé
    user = Accounts.get_user!(user_id)

    if user.validated do
      %CrewMember{}
      |> CrewMember.changeset(%{
        crew_id: crew.id,
        user_id: user.id,
        is_manager: false
      })
      |> Repo.insert()
    else
      {:error, :user_not_validated}
    end
  end

  def get_user_crew(user) do
    from(cm in CrewMember,
      where: cm.user_id == ^user.id,
      join: c in Crew, on: c.id == cm.crew_id,
      select: c
    )
    |> Repo.one()
  end
end
```

#### Permissions (Controller)
```elixir
defmodule HoMonRadeauWeb.CrewJoinRequestController do
  plug :require_validated_user when action in [:create]
  plug :require_manager when action in [:accept, :reject]

  def create(conn, %{"crew_id" => crew_id, "message" => message}) do
    crew = Events.get_crew!(crew_id)
    user = conn.assigns.current_user

    case Events.create_join_request(crew, user, message) do
      {:ok, _request} ->
        conn
        |> put_flash(:info, "Votre demande a été envoyée.")
        |> redirect(to: Routes.raft_path(conn, :show, crew.raft_id))

      {:error, :already_in_crew} ->
        conn
        |> put_flash(:error, "Vous êtes déjà membre d'un équipage.")
        |> redirect(to: Routes.raft_path(conn, :show, crew.raft_id))
    end
  end
end
```

### Sécurité
- Vérifier la validation de l'utilisateur avant ajout
- Vérifier les permissions gestionnaire avant validation de demande
- Empêcher les demandes multiples au même radeau (unique constraint)
- Logger les ajouts et validations

### Performance
- Index sur `crew_join_requests.status` pour filtrer les demandes en attente
- Index sur `crew_join_requests.user_id` pour trouver les demandes d'un user
- Précharger les relations user/crew dans les listes

### UX
- Badge visible "En attente de validation" pour les demandes d'utilisateurs non validés
- Notifications claires après acceptation/refus
- Annulation automatique des autres demandes si accepté ailleurs
- Message clair si l'utilisateur est déjà membre d'un équipage
