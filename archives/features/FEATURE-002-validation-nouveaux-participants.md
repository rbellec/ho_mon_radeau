# FEATURE-002 : Validation des nouveaux participants

## Description
Système de validation des nouveaux utilisateurs par l'équipe d'accueil ou les administrateurs avant qu'ils puissent s'inscrire à un équipage. Cette étape permet de s'assurer que tous les participants ont été contactés et validés par l'organisation.

## Objectif
Assurer la sécurité et la conformité avec les demandes de la préfecture en s'assurant qu'un membre de l'équipe d'accueil a discuté avec chaque nouvelle personne avant qu'elle ne puisse rejoindre un radeau. Cette validation permet également de préserver l'esprit de l'événement et de s'assurer que tout.e participant.e comprend les spécificités de Tutto Blu.

## Utilisateurs concernés
- **Nouveaux utilisateurs** : Doivent être validés pour pouvoir s'inscrire à un équipage
- **Équipe d'accueil des nouveaux** : Valide les nouveaux après entretien
- **Administrateurs** : Peuvent également valider les utilisateurs
- **Utilisateurs "connus"** : Peuvent être pré-validés ou validés rapidement

## Comportement attendu

### Pour l'utilisateur non validé
1. Après inscription et validation d'email, statut = "non validé"
2. **Peut consulter :**
   - Tous les contenus publics de l'application
   - Liste des radeaux
   - Pages publiques des radeaux
   - Forum (lien externe)
3. **Ne peut PAS :**
   - S'inscrire à un équipage
   - Faire une demande d'adhésion à un radeau
   - Créer un radeau (à clarifier ?)

### Pour l'équipe d'accueil
1. **Accès à la liste des utilisateurs non validés**
   - Affichage des pseudos uniquement
   - Pas d'accès aux données personnelles (nom, prénom, téléphone)
2. **Processus de validation :**
   - Entretien avec la personne (hors application, via WhatsApp/téléphone)
   - Validation dans l'application :
     - **Option 1 :** Valider par pseudo
     - **Option 2 :** Entrer l'email ou le numéro de téléphone dans un formulaire (demandé directement à la personne)
3. Une fois validé, l'utilisateur peut rejoindre un équipage

### Pour les administrateurs
1. **Accès complet aux données utilisateurs**
   - Liste de tous les utilisateurs (validés et non validés)
   - Accès aux données personnelles (email, nom, prénom, téléphone)
2. **Peuvent valider n'importe quel utilisateur** directement

## Règles métier

### Validation
- Un utilisateur non validé ne peut pas s'inscrire à un radeau
- La validation est **irréversible** (mais un admin peut la retirer si nécessaire)
- Les utilisateurs "connus" peuvent être pré-validés lors de leur inscription

### Droits différenciés
- **Équipe d'accueil :**
  - Liste des pseudos uniquement
  - Validation par pseudo ou coordonnées (email/téléphone)
- **Administrateurs :**
  - Accès à toutes les données personnelles
  - Validation directe de n'importe quel utilisateur

### Processus externe
- L'entretien de validation se fait **hors application** (WhatsApp, téléphone, forum)
- L'application sert uniquement à **enregistrer la validation**

## Interface utilisateur

### Page pour équipe d'accueil
**Liste des utilisateurs non validés :**
- Tableau avec colonnes :
  - Pseudo (ou "pas de pseudo")
  - Date d'inscription
  - Statut (non validé)
  - Actions (bouton "Valider")
- Filtre : afficher uniquement les non validés

**Formulaire de validation :**
- Option 1 : Cliquer sur "Valider" à côté d'un pseudo
- Option 2 : Formulaire avec champ "Email ou téléphone" → bouton "Valider"
- Confirmation de la validation

### Page pour administrateurs
**Liste complète des utilisateurs :**
- Tableau avec colonnes :
  - Pseudo
  - Email
  - Nom/Prénom
  - Téléphone
  - Date d'inscription
  - Statut (validé/non validé)
  - Actions (bouton "Valider" / "Révoquer")
- Filtres : validé/non validé, recherche par nom/email/pseudo

### Pour l'utilisateur non validé
- **Badge/message clair** sur le profil : "En attente de validation"
- Message explicatif : "Votre compte doit être validé par l'équipe d'accueil avant de pouvoir rejoindre un radeau. Un membre de l'équipe vous contactera prochainement."
- Lien vers le forum pour poser des questions

## Dépendances
- **FEATURE-001** (Inscription utilisateur) : Base de la validation
- **FEATURE-010** (Équipes transverses) : Équipe d'accueil comme équipe transverse
- **Système d'authentification** : Vérification du statut de validation avant actions

## Notes techniques

### Implémentation

#### Base de données
- Champ `users.validated` (boolean, default: false)
- Champ `users.validated_at` (datetime, nullable)
- Champ `users.validated_by_id` (foreign key vers users, nullable)

#### Permissions
- Définir un rôle `welcome_team` (équipe d'accueil)
- Définir un rôle `admin`
- Scope des requêtes selon le rôle :
  ```elixir
  # Pour équipe d'accueil : uniquement pseudos
  from u in User,
    where: u.validated == false,
    select: %{id: u.id, nickname: u.nickname, inserted_at: u.inserted_at}

  # Pour admins : toutes les données
  from u in User,
    where: u.validated == false
  ```

#### Validation par coordonnées
- Formulaire acceptant email OU téléphone
- Recherche de l'utilisateur correspondant
- Validation si trouvé, erreur si non trouvé

#### Middleware/Plug
- Créer un plug `RequireValidated` pour protéger les actions nécessitant validation
- Appliquer sur les controllers/actions concernés :
  - Création de radeau (?)
  - Demande d'adhésion à un radeau
  - Ajout à un équipage

### Sécurité
- Vérifier les permissions avant affichage des données
- Logger les validations (qui a validé qui et quand)
- Protection contre l'élévation de privilèges

### UX
- Message clair pour les utilisateurs non validés
- Ne pas frustrer : donner accès à la consultation
- Contact clair : lien vers forum ou informations de contact équipe d'accueil
