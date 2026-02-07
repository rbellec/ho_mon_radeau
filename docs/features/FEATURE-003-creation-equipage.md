# FEATURE-003 : Création d'équipage

## Description
Permet à un utilisateur validé de créer un nouvel équipage/radeau pour l'événement Tutto Blu. Un équipage est lié à un radeau (relation 1-1) et représente le groupe de personnes qui construiront et navigueront ensemble.

## Objectif
Permettre aux participants de former leurs propres équipages de manière autonome, en initialisant la structure de base (nom de radeau, gestionnaires) qui sera ensuite enrichie par d'autres membres.

## Utilisateurs concernés
- **Utilisateurs validés** : Peuvent créer un équipage
- **Futurs membres** : Pourront rejoindre l'équipage créé
- **Administrateurs** : Valideront l'équipage pour participation

## Comportement attendu

### Conditions pour créer un équipage
- Utilisateur doit être **validé** (FEATURE-002)
- Utilisateur ne doit pas déjà être membre d'un équipage (ou clarifier si possible d'être dans plusieurs ?)

### Formulaire de création
L'utilisateur renseigne :
1. **Nom du radeau** (obligatoire, unique)
   - Sera utilisé comme identifiant de l'équipage
   - Visible publiquement
2. **Description** (optionnelle)
   - Présentation de l'équipage
   - Visible publiquement
3. **Lien forum Discourse** (optionnel)
   - URL vers la discussion de l'équipage sur le forum
   - Permet aux personnes intéressées d'en discuter

### Après création
1. **Créateur = premier gestionnaire** automatiquement
2. **Statut initial : "radeau proposé"** (non validé par admin)
3. L'utilisateur est redirigé vers **la page privée du radeau**
4. Le radeau apparaît dans **la liste des radeaux** (public)

### Relation radeau-équipage
- **1 radeau = 1 équipage** (relation 1-1)
- Dans le langage, les deux termes sont souvent utilisés de manière interchangeable
- Techniquement : 2 entités possibles mais liées de manière unique

## Règles métier

### Nom du radeau
- **Unique** dans toute l'application
- Obligatoire
- Visible publiquement
- Peut contenir espaces, caractères spéciaux (à définir limites)

### Gestionnaires
- **Créateur = gestionnaire initial**
- Le créateur peut :
  - Ajouter d'autres gestionnaires (FEATURE-004)
  - Quitter l'équipage (même sans participer à l'événement)
- Si le créateur quitte ET qu'il n'y a plus de gestionnaire :
  - Un admin peut promouvoir un membre en gestionnaire
  - Pas de promotion automatique

### Validation admin
- Nouveau radeau = statut "proposé"
- Admin peut valider → statut "participant"
- Impact sur affichage dans les listes (FEATURE-009)

### Limite de création
- Un utilisateur peut-il créer plusieurs radeaux ? **À clarifier**
- Un utilisateur peut-il être dans plusieurs équipages ? **À clarifier**

## Interface utilisateur

### Bouton de création
- Visible sur la page d'accueil ou page "Liste des radeaux"
- Label : "Créer un radeau" ou "Créer mon équipage"
- Visible uniquement si utilisateur validé

### Formulaire de création
```
Créer un nouveau radeau

Nom du radeau *
[_____________________]
(Le nom doit être unique)

Description
[_____________________]
[_____________________]
[_____________________]

Lien forum (optionnel)
[_____________________]
(Lien vers la discussion Discourse de votre équipage)

[Créer le radeau]  [Annuler]
```

### Retour après création
- Message de succès : "Votre radeau [NOM] a été créé !"
- Information : "Vous êtes maintenant gestionnaire de cet équipage."
- Redirection automatique vers la page privée du radeau

### Gestion des erreurs
- Nom déjà pris : "Ce nom de radeau existe déjà, veuillez en choisir un autre."
- Utilisateur non validé : "Vous devez être validé pour créer un radeau."
- Champs manquants : Messages clairs par champ

## Dépendances
- **FEATURE-001** (Inscription utilisateur) : Base utilisateur
- **FEATURE-002** (Validation nouveaux) : Utilisateur doit être validé
- **FEATURE-004** (Gestion gestionnaires) : Pour nommer d'autres gestionnaires
- **FEATURE-007** (Pages publiques) : Affichage du radeau dans la liste
- **FEATURE-008** (Pages privées) : Redirection après création
- **FEATURE-009** (Validation admin) : Statut du radeau

## Notes techniques

### Implémentation

#### Base de données
Tables principales :
```elixir
# Radeau (objet physique)
create table :rafts do
  add :name, :string, null: false
  add :description, :text
  add :forum_url, :string
  add :picture_url, :string
  add :validated, :boolean, default: false
  add :validated_at, :datetime
  add :validated_by_id, references(:users)

  timestamps()
end

# Index unique sur le nom
create unique_index(:rafts, [:name])

# Équipage (groupe)
create table :crews do
  add :raft_id, references(:rafts), null: false

  timestamps()
end

# Relation 1-1
create unique_index(:crews, [:raft_id])

# Membres d'équipage
create table :crew_members do
  add :crew_id, references(:crews), null: false
  add :user_id, references(:users), null: false
  add :is_manager, :boolean, default: false
  add :role, :string  # capitaine, lead_construction, etc.

  timestamps()
end

# Un user ne peut être dans un équipage qu'une fois
create unique_index(:crew_members, [:crew_id, :user_id])
```

#### Contexte Elixir
```elixir
defmodule HoMonRadeau.Events do
  def create_raft_with_crew(user, attrs) do
    # Transaction pour créer radeau + équipage + premier membre gestionnaire
    Multi.new()
    |> Multi.insert(:raft, Raft.changeset(%Raft{}, attrs))
    |> Multi.insert(:crew, fn %{raft: raft} ->
      Crew.changeset(%Crew{}, %{raft_id: raft.id})
    end)
    |> Multi.insert(:creator_member, fn %{crew: crew} ->
      CrewMember.changeset(%CrewMember{}, %{
        crew_id: crew.id,
        user_id: user.id,
        is_manager: true
      })
    end)
    |> Repo.transaction()
  end
end
```

#### Validations
- Nom unique (constraint)
- Nom non vide
- URL forum valide si présente
- Utilisateur validé (plug)

#### Permissions
- Middleware `RequireValidated` sur l'action de création

### Sécurité
- Vérifier que l'utilisateur est validé
- Vérifier unicité du nom (constraint DB)
- Logger la création (qui, quand, quel radeau)

### Performance
- Index sur `rafts.name` (unique)
- Index sur `crew_members.user_id` pour retrouver l'équipage d'un user
- Index sur `crew_members.crew_id` pour lister les membres

### UX
- Autocomplétion pour vérifier disponibilité du nom en temps réel (optionnel)
- Confirmation visuelle claire après création
- Lien vers forum pré-rempli si pattern connu
