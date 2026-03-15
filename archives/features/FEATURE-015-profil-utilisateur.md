# FEATURE-015 : Page profil utilisateur

## Description
Chaque utilisateur dispose d'une page profil où il peut consulter et modifier ses informations personnelles : pseudo, nom/prénom, numéro de téléphone, photo de profil et paramètre de visibilité de la photo. C'est aussi là qu'il voit son statut de validation et son appartenance à un équipage.

## Objectif
Permettre à chaque utilisateur de maintenir ses informations à jour et de contrôler sa visibilité publique. Les données du profil impactent l'affichage sur les pages publiques des radeaux et les capacités de participation à l'événement.

## Utilisateurs concernés
- **Tout utilisateur connecté** : accède à son propre profil
- **Administrateurs** : peuvent voir les profils complets via Kaffy (FEATURE-014)

## Comportement attendu

### Accès
- URL : `/mon-profil` ou `/profil` (redirige vers la page du profil connecté)
- Accessible depuis la navigation principale (menu utilisateur)

### Informations affichées

#### Statut du compte
```
Statut : ✓ Compte validé
         ⏳ En attente de validation par l'équipe d'accueil
```

#### Informations publiques
- **Pseudo** (toujours public s'il est renseigné)
- **Photo de profil** avec paramètre de visibilité

#### Informations privées (visibles uniquement par l'utilisateur, son équipage et les admins)
- Nom / Prénom
- Numéro de téléphone
- Email (lecture seule — modification via le flux phx.gen.auth)

#### Appartenance
- Nom du radeau si membre d'un équipage, avec lien vers la page privée
- Équipes transverses dont l'utilisateur est membre

### Modification du profil

#### Champs modifiables
- Pseudo
- Prénom / Nom
- Numéro de téléphone
- Photo de profil (upload ou suppression)
- Visibilité de la photo (`publique` / `privée`)

#### Champs non modifiables ici
- Email → flux dédié phx.gen.auth (`/utilisateurs/parametres`)
- Mot de passe → flux dédié phx.gen.auth

### Upload de photo de profil

#### Workflow
1. Utilisateur clique "Changer la photo"
2. Sélection d'un fichier image (JPEG, PNG, WebP)
3. Prévisualisation avant confirmation
4. Upload vers Tigris (S3-compatible)
5. Ancien fichier supprimé du stockage

#### Contraintes
- Formats acceptés : JPEG, PNG, WebP
- Taille maximale : 5 MB
- La photo est redimensionnée côté serveur (max 400×400px, optionnel)

#### Visibilité de la photo
- **Publique** : affichée sur la page publique des radeaux et partout
- **Privée** : affichée uniquement dans les pages de l'équipage et aux admins

### Suppression de la photo
- L'utilisateur peut supprimer sa photo (revient à l'avatar générique)
- Le fichier est supprimé de Tigris

## Règles métier

### Pseudo
- Toujours public s'il est renseigné
- Modification possible à tout moment
- Unicité non requise (deux utilisateurs peuvent avoir le même pseudo)

### Nom / Prénom
- Optionnels à l'inscription
- Deviennent obligatoires pour participer à l'événement (validation CUF) — l'app affiche un rappel

### Photo de profil
- Stockée dans Tigris, pas de lien externe pour les photos de profil
- Clé de stockage : `profile_pictures/{user_id}/{timestamp}_{filename}`
- La valeur en base est la clé Tigris (pas une URL directe) — URL pré-signée générée à l'affichage

## Interface utilisateur

### Page profil
```
┌─────────────────────────────────────────────────────┐
│                                                     │
│  [Photo]  Pseudo42                                  │
│           ✓ Compte validé                           │
│           Membre de : Radeau La Loutre →            │
│                                                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Photo de profil                                    │
│  [Photo actuelle]  [Changer] [Supprimer]            │
│  Visibilité : ● Publique  ○ Privée                  │
│                                                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Informations personnelles                          │
│  Pseudo         [Pseudo42_____________]             │
│  Prénom         [Jean__________________]            │
│  Nom            [Dupont________________]            │
│  Téléphone      [06 12 34 56 78________]            │
│                                                     │
│  ⚠️ Prénom et Nom sont requis pour participer        │
│     à l'événement.                                  │
│                                                     │
│  [Enregistrer les modifications]                    │
│                                                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Paramètres du compte                               │
│  Email : jean@example.com [Modifier →]              │
│  Mot de passe : ••••••••  [Modifier →]              │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Message si non validé
```
⏳ Votre compte est en attente de validation par l'équipe
   d'accueil. Vous pourrez rejoindre un équipage une fois
   validé·e.

   Des questions ? Rendez-vous sur le forum →
```

## Dépendances
- **FEATURE-001** (Inscription) : Données initiales du profil
- **FEATURE-002** (Validation) : Affichage du statut de validation
- **FEATURE-003/005** (Équipage) : Affichage de l'appartenance
- **FEATURE-013** (Fiches) : Stockage Tigris — même infrastructure

## Notes techniques

### Stockage Tigris
Même configuration que FEATURE-013 (voir ses notes techniques pour la config `ex_aws`).

Clé des photos de profil :
```
profile_pictures/{user_id}/{timestamp}_{original_filename}
```

### Schéma User — champs existants
```elixir
field :nickname, :string
field :first_name, :string
field :last_name, :string
field :phone_number, :string
field :profile_picture_url, :string   # Clé Tigris (pas URL directe)
field :profile_picture_public, :boolean, default: false
```

### Contexte
```elixir
defmodule HoMonRadeau.Accounts do
  def update_profile(user, attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
  end

  def upload_profile_picture(user, file_path, original_filename) do
    key = "profile_pictures/#{user.id}/#{timestamp()}_#{original_filename}"

    # Upload vers Tigris
    :ok = Storage.upload(key, file_path)

    # Supprimer l'ancienne si elle existe
    if user.profile_picture_url do
      Storage.delete(user.profile_picture_url)
    end

    # Mettre à jour l'utilisateur
    update_profile(user, %{profile_picture_url: key})
  end

  def get_profile_picture_url(user) do
    if user.profile_picture_url do
      Storage.presigned_url(user.profile_picture_url, expires_in: 3600)
    else
      nil  # Afficher un avatar générique
    end
  end
end
```

### Sécurité
- Vérifier que l'utilisateur modifie uniquement son propre profil
- Validation du type MIME côté serveur (pas seulement côté client)
- Limite de taille vérifiée avant upload
- URLs pré-signées avec expiration courte pour les photos

### UX
- Prévisualisation de la photo avant confirmation
- Message clair si prénom/nom manquants (requis pour CUF)
- Lien direct vers le flux email/mot de passe de phx.gen.auth
