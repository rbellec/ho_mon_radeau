# FEATURE-001 : Inscription utilisateur

## Description
Permet à toute personne de créer un compte sur l'application HoMonRadeau afin de pouvoir consulter les radeaux, rejoindre un équipage ou créer son propre radeau.

## Objectif
Permettre l'inscription libre sur la plateforme tout en maintenant un processus de validation pour la participation effective à l'événement. L'inscription est la première étape avant toute interaction avec l'application.

## Utilisateurs concernés
- Toute personne souhaitant participer ou s'informer sur l'événement Tutto Blu
- Nouveaux arrivants découvrant l'événement
- Anciens participants revenant pour une nouvelle édition

## Comportement attendu

### Formulaire d'inscription
L'utilisateur doit renseigner :
- **Email** (obligatoire, unique) : Validation par lien email requis
- **Pseudo** (optionnel) : Affiché publiquement
- **Mot de passe** (obligatoire)

### Données optionnelles à ce stade
- Nom et prénom : Optionnels à l'inscription mais **requis pour participer à l'événement**
- Photo de profil : Optionnelle
- Numéro de téléphone : Optionnel

### Après inscription
1. L'utilisateur reçoit un email de validation
2. Il valide son email via le lien reçu
3. Il peut se connecter à l'application
4. **Statut initial : "non validé"**
   - Peut consulter tous les contenus publics
   - Peut voir la liste des radeaux
   - **Ne peut PAS** s'inscrire à un radeau tant qu'il n'est pas validé par l'équipe d'accueil

## Règles métier

### Validation email
- Email obligatoire et unique dans la base
- Validation par lien envoyé par email (phx.gen.auth)
- L'utilisateur ne peut se connecter qu'après validation de l'email

### Pseudo
- Le pseudo est **toujours public** s'il est renseigné
- Les utilisateurs sans pseudo sont affichés comme "matelot sans pseudonyme"
- Le pseudo peut être modifié à tout moment par l'utilisateur

### Photo de profil
- Photo stockée dans l'application (pas de lien externe)
- Visibilité configurable :
  - **Publique** : affichée partout
  - **Non publique** : affichée uniquement dans les équipes, le radeau de l'équipier, et aux admins

### Données personnelles complètes
- Nom/prénom optionnels à l'inscription
- Deviennent **obligatoires pour participer à l'événement** (validation ultérieure)

## Interface utilisateur

### Page d'inscription
- Formulaire simple avec champs email, pseudo (opt.), mot de passe
- Lien vers conditions d'utilisation
- Lien vers page de connexion pour utilisateurs existants

### Page de profil utilisateur
- Édition des informations personnelles
- Configuration de la visibilité de la photo de profil
- Indication claire du statut de validation ("Compte validé" / "En attente de validation")

## Dépendances
- **phx.gen.auth** : Système d'authentification Phoenix
- **Service d'email** : Envoi des emails de validation (Mailcatcher en dev)
- **FEATURE-002** (Validation des nouveaux participants) : Pour le workflow de validation

## Notes techniques

### Implémentation
- Utiliser `mix phx.gen.auth` pour générer le système d'authentification
- Tables principales :
  - `users` : informations utilisateur
  - `users_tokens` : tokens de validation/session
- Champs additionnels à ajouter au schéma User :
  - `nickname` (string, nullable)
  - `first_name` (string, nullable)
  - `last_name` (string, nullable)
  - `phone_number` (string, nullable)
  - `profile_picture_url` (string, nullable)
  - `profile_picture_public` (boolean, default: false)
  - `validated` (boolean, default: false) - pour la validation par équipe d'accueil

### Sécurité
- Validation email obligatoire avant connexion
- Mot de passe hashé (bcrypt via phx.gen.auth)
- Protection contre les inscriptions multiples (email unique)

### Performance
- Index sur email (unique)
- Index sur nickname pour recherches
