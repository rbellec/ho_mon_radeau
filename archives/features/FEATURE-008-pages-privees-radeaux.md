# FEATURE-008 : Pages privées des radeaux

## Description
Chaque radeau dispose d'une page privée accessible uniquement aux membres de l'équipage, offrant des fonctionnalités de gestion et d'organisation : gestion des membres, des rôles, des demandes d'adhésion, des bidons, de la CUF, et accès aux outils de coordination de l'équipage.

## Objectif
Fournir un espace de travail dédié à chaque équipage pour gérer leur organisation interne, suivre leur progression (bidons, CUF, rôles), et coordonner leurs activités. Centraliser les informations importantes tout en renvoyant vers les outils externes (forum, WhatsApp) pour les discussions.

## Utilisateurs concernés
- **Membres de l'équipage** : Accès complet à la page privée de leur radeau
- **Gestionnaires** : Fonctionnalités de gestion supplémentaires
- **Capitaine** : Fonctionnalités spécifiques (CUF)
- **Administrateurs** : Accès à toutes les pages privées (mode lecture/intervention)

## Comportement attendu

### Accès à la page privée

#### Redirection après connexion
- **Membre d'un équipage** : Redirigé automatiquement vers la page privée de son radeau
- **Non-membre** : Redirigé vers la liste des radeaux

#### URL
`/mon-radeau` ou `/radeaux/[id]/prive`

### Structure de la page privée

La page est organisée en plusieurs sections :

#### 1. En-tête / Informations générales
```
RADEAU [NOM]
[Photo du radeau]
Badge : [Participant] / [Proposé]

[Modifier les informations] (gestionnaires uniquement)
```

#### 2. État de l'équipage
```
État de l'équipage
------------------
✓ Capitaine : Pseudo1
⚠️ Lead construction : personne
✓ Cuisine : Pseudo2
✓ Interlocuteur SAFE : Pseudo3

Membres : 12
Gestionnaires : Pseudo1, Pseudo4

[Gérer les rôles]
```

#### 3. CUF (Cotisation)
```
Cotisation Urbaine Flottante (CUF)
-----------------------------------
Participants déclarés : 10
Membres actuels : 12
CUF restant à régler : 2

Statut : ⚠️ En attente de paiement

[Gérer la CUF] (capitaine uniquement)
```

#### 4. Bidons
```
Bidons
------
Demande actuelle : 80 bidons
Montant : 400 € (5€/bidon)
Statut : ✓ Paiement validé

[Gérer les bidons]
```

#### 5. Membres et demandes
```
Membres de l'équipage (12)
--------------------------
[Liste complète des membres avec rôles]

Demandes d'adhésion (3)
-----------------------
[Liste des demandes en attente]
[Accepter] [Refuser]
```

#### 6. Outils et ressources
```
Communication
-------------
💬 Forum de l'équipage
→ https://tuttoblu.discourse.group/t/...

💬 Groupe WhatsApp
[Ajouter le lien] (gestionnaires)

Documents internes
------------------
+ Ajouter un lien

Rappels
-------
ℹ️ Cotisation à la base flottante
Montant estimé : XXX € (selon nombre de nuits)
Plus d'infos : [lien]
```

### Fonctionnalités selon le rôle

#### Tous les membres
- Consulter toutes les informations
- Modifier leurs propres rôles (auto-déclaration)
- Voir les coordonnées complètes des autres membres (email, téléphone si renseignés)
- Accéder aux liens et documents

#### Gestionnaires
- Modifier les informations du radeau (nom, description, photo, liens)
- Gérer les membres (ajouter, retirer)
- Valider les demandes d'adhésion
- Nommer/retirer des gestionnaires
- Attribuer le capitaine
- Gérer les bidons

#### Capitaine
- Gérer la CUF (déclarer les participants, montant)
- Toutes les fonctions des gestionnaires (si aussi gestionnaire)

#### Administrateurs
- Accès à toutes les pages privées
- Mode lecture avec possibilité d'intervention
- Fonctions spéciales (valider radeau, promouvoir gestionnaire si équipage sans gestionnaire)

## Règles métier

### Accès restreint
- **Seuls les membres de l'équipage** peuvent accéder à la page privée
- Tentative d'accès par non-membre : redirection vers page publique
- Exception : administrateurs ont accès à toutes les pages privées

### Visibilité des données personnelles
Sur la page privée, les membres voient :
- Pseudo de tous les membres
- Photos de profil (publiques ET non publiques)
- Email (si renseigné)
- Nom/prénom (si renseignés)
- Numéro de téléphone (si renseigné)

### Sections conditionnelles
- **CUF** : Visible par tous, gérable par le capitaine uniquement
- **Bidons** : Visible par tous, gérable par gestionnaires
- **Demandes d'adhésion** : Visibles par tous, validables par gestionnaires

### Placeholder cotisation base flottante
- Section informative (non gérable dans l'app)
- Montant estimé basé sur nombre de nuits (à paramétrer)
- Lien vers plus d'informations

## Interface utilisateur

### Layout général
```
┌─────────────────────────────────────────────────────────┐
│ [Logo] Tutto Blu                    [Pseudo] [Déconnexion] │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  RADEAU LA LOUTRE                                       │
│  [Photo]                          [Modifier] (si gest.) │
│  Badge: Participant                                     │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  État de l'équipage                                     │
│  ✓ Capitaine : Alice                                    │
│  ⚠️ Lead construction : personne                         │
│  ...                                                     │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  CUF - Cotisation Urbaine Flottante                     │
│  Participants déclarés : 10                             │
│  CUF restant à régler : 2                               │
│  [Gérer la CUF] (capitaine)                             │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Bidons                                                 │
│  80 bidons - 400€ - Paiement validé ✓                   │
│  [Gérer les bidons]                                     │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Membres (12) | Demandes (3)                            │
│  [Onglets]                                              │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Outils et ressources                                   │
│  💬 Forum | 📱 WhatsApp | 📁 Documents                   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Page d'édition (gestionnaires)
```
Modifier les informations du radeau

Photo du radeau
[Image actuelle]
[Changer la photo]

Nom du radeau *
[La Loutre____________]

Description
[_____________________]
[_____________________]
[_____________________]

Lien forum Discourse
[https://tuttoblu.discourse.group/t/...]

Lien WhatsApp
[https://chat.whatsapp.com/...]

[Enregistrer] [Annuler]
```

### Section membres détaillée
```
Membres de l'équipage (12)
--------------------------

Gestionnaires (2)
[Photo] Alice42 (Capitaine) ★
Email: alice@example.com | Tél: 06 12 34 56 78
Rôles: Capitaine, Cuisine
[Retirer gestionnaire] [Retirer de l'équipage]

[Photo] BobBuilder
Email: bob@example.com
Rôles: Lead construction
[Retirer gestionnaire] [Retirer de l'équipage]

Membres (10)
[Photo] Charlie
Email: charlie@example.com
Rôles: Interlocuteur SAFE
[Nommer gestionnaire] [Retirer de l'équipage]

[Photo] Diana
Rôles: Cuisine
[Nommer gestionnaire] [Retirer de l'équipage]

...

[+ Ajouter un membre]
```

## Dépendances
- **FEATURE-003** (Création équipage) : Structure de base
- **FEATURE-004** (Gestionnaires) : Permissions
- **FEATURE-005** (Adhésion) : Demandes et ajout membres
- **FEATURE-006** (Rôles) : Affichage et gestion des rôles
- **FEATURE-011** (Bidons) : Section bidons
- **FEATURE-012** (CUF) : Section CUF

## Notes techniques

### Implémentation

#### Routes
```elixir
scope "/", HoMonRadeauWeb do
  pipe_through [:browser, :require_authenticated_user]

  get "/mon-radeau", CrewController, :show_mine
  get "/radeaux/:id/prive", CrewController, :show_private

  # Gestionnaires uniquement
  scope "/radeaux/:id" do
    pipe_through :require_manager

    get "/edit", RaftController, :edit
    put "/", RaftController, :update
    post "/members", CrewMemberController, :create
    delete "/members/:member_id", CrewMemberController, :delete
  end
end
```

#### Controller
```elixir
defmodule HoMonRadeauWeb.CrewController do
  def show_mine(conn, _params) do
    user = conn.assigns.current_user
    crew = Events.get_user_crew(user)

    if crew do
      redirect(conn, to: Routes.crew_path(conn, :show_private, crew.id))
    else
      redirect(conn, to: Routes.raft_path(conn, :index))
    end
  end

  def show_private(conn, %{"id" => id}) do
    crew = Events.get_crew!(id)
    user = conn.assigns.current_user

    # Vérifier que l'user est membre ou admin
    if Events.is_crew_member?(crew, user) or user.is_admin do
      raft = crew.raft
      members = Events.get_crew_members_full(crew)
      join_requests = Events.get_pending_join_requests(crew)
      captain = Events.get_captain(crew)
      missing_roles = Events.get_missing_roles(crew)

      # Données CUF
      cuf_data = CUF.get_crew_cuf_summary(crew)

      # Données bidons
      drums_data = Drums.get_crew_drums_summary(crew)

      render(conn, "show_private.html",
        crew: crew,
        raft: raft,
        members: members,
        join_requests: join_requests,
        captain: captain,
        missing_roles: missing_roles,
        cuf_data: cuf_data,
        drums_data: drums_data,
        is_manager: Events.is_manager?(crew, user),
        is_captain: Events.is_captain?(crew, user)
      )
    else
      conn
      |> put_flash(:error, "Vous n'avez pas accès à cette page.")
      |> redirect(to: Routes.raft_path(conn, :show, crew.raft_id))
    end
  end
end
```

#### Contexte
```elixir
defmodule HoMonRadeau.Events do
  def get_crew_members_full(crew) do
    from(cm in CrewMember,
      where: cm.crew_id == ^crew.id,
      join: u in User, on: u.id == cm.user_id,
      select: %{
        id: cm.id,
        user: u,
        is_manager: cm.is_manager,
        is_captain: cm.is_captain,
        roles: cm.roles
      },
      order_by: [desc: cm.is_manager, desc: cm.is_captain, asc: u.nickname]
    )
    |> Repo.all()
  end

  def is_crew_member?(crew, user) do
    from(cm in CrewMember,
      where: cm.crew_id == ^crew.id and cm.user_id == ^user.id
    )
    |> Repo.exists?()
  end
end
```

#### Permissions (Plugs)
```elixir
defmodule HoMonRadeauWeb.Plugs.RequireCrewMember do
  def init(opts), do: opts

  def call(conn, _opts) do
    crew_id = conn.params["id"]
    user = conn.assigns.current_user

    if Events.is_crew_member?(crew_id, user) or user.is_admin do
      conn
    else
      conn
      |> put_flash(:error, "Vous devez être membre de cet équipage.")
      |> redirect(to: Routes.raft_path(conn, :index))
      |> halt()
    end
  end
end
```

### Sécurité
- Vérifier l'appartenance à l'équipage avant affichage
- Vérifier les permissions (gestionnaire, capitaine) avant actions
- Masquer les boutons d'action selon les droits
- Logger les actions sensibles (ajout/retrait membre, modification CUF/bidons)

### Performance
- Précharger toutes les relations nécessaires en une seule requête
- Cache des données calculées (CUF restant, nombre de bidons, etc.)
- Index sur les jointures fréquentes

### UX
- Dashboard clair avec sections bien séparées
- Badges visuels pour les statuts (validé, en attente, complet)
- Alertes visuelles pour les actions requises (rôles manquants, CUF à régler)
- Accès rapide aux outils externes (forum, WhatsApp)
- Responsive design pour mobile
- Notifications pour les événements importants (nouveau membre, demande d'adhésion)
