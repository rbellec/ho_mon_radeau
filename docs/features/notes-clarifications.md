# Notes de Clarification - Session Tutto Blu

## Contexte général de l'événement

**Tutto Blu** : Événement où les participants construisent des radeaux puis lancent "la dérive" sur un lac.

- Participants regroupés par **équipages**
- Équipes transverses : sécurité, SAFE, médecine, accueil des nouveaux, bidons
- Pour les admins, on s'adresse aux équipages (pas aux individus)
- Nouveaux participants doivent être validés par l'équipe accueil

**Philosophie de l'application :**
- Limiter les features locales
- Discussions sur forum Discourse (https://tuttoblu.discourse.group/) et WhatsApp
- L'app complète ces outils, ne les remplace pas

---

## Q&A Session 1

### Q1 - Équipage vs Radeau
**Réponse :** Relation 1-1. Le radeau est l'objet physique, l'équipage est le groupe. Deux entités potentiellement distinctes mais liées de manière unique. Dans le langage, on confond souvent les deux termes.

**Important :** Un utilisateur ne peut être membre que d'**un seul équipage** à la fois, mais peut être membre de **plusieurs équipes transverses** en parallèle.

### Q2 - Équipes transverses
**Réponse :**
- Différentes des équipages de radeau
- Pas listées parmi les radeaux
- Peuvent être gérées comme les équipages
- **Visibilité :** uniquement par leurs membres et les admins (pas publiques)

### Q3 - Workflow de validation des nouveaux
**Réponse :**
- User "non validé" peut **tout voir** dans l'app
- User "non validé" **ne peut PAS s'inscrire à un radeau** avant validation
- **Qui peut valider :** Équipe de validation des nouveaux + Admins
- **Droits différenciés :**
  - **Admins :** accès à tous les utilisateurs avec données perso
  - **Équipe de validation :** peut seulement lister les pseudos
- **Méthode de validation :**
  - Soit valider un pseudo directement
  - Soit entrer numéro de téléphone ou email dans un formulaire (demandé directement à la personne)

### Q4 - Rejoindre un équipage
**Réponse :**
- **Ajout direct :** Gestionnaire peut ajouter un membre
- **Demande d'adhésion :** Membre peut faire une demande
- **Liste des demandes :** L'équipage voit la liste des demandes
- **Validation :** Seuls les gestionnaires peuvent valider l'adhésion
- **Restriction :** Membre "non validé" ne peut pas être ajouté, mais sa demande peut être affichée

### Q5 - Gestionnaires d'équipage
**Réponse :**
- **Pas de différence de droits** entre créateur et autres gestionnaires
- Créateur peut même quitter l'équipe, ne pas participer à l'événement
- **Si plus de gestionnaire :** Un admin peut promouvoir un membre (pas de promotion automatique)
- **Droits :** Tous les gestionnaires ont les mêmes droits

### Q6 - Rôles obligatoires
**Réponse :** À voir plus tard. La validation de participation sera une feature travaillée ultérieurement.

### Q7 - Attribution des rôles
**Réponse :**
- Un participant peut avoir **plusieurs rôles**
- **Un seul capitaine** par radeau
- **Auto-déclaration :** Chaque participant peut se déclarer sur un rôle, SAUF pour gestionnaire et capitaine
- **Gestionnaire et capitaine :** Attribués différemment (pas d'auto-déclaration)

### Q8 - Impact de la validation admin des radeaux
**Réponse :**
- Il y aura une **liste des radeaux participants** et une **liste des radeaux proposés**
- Alternative plus simple : **même liste avec participants en premier**
- **Volumétrie :** Moins de 50 radeaux sur l'événement

**Additionnel :**
- **Feature recherche multi-critères pour admins** (à décrire plus tard)
- **Critères de recherche :**
  - Nom de radeau
  - Validation (validé ou non)
  - Équipage complet ou pas
  - CUF (cotisation) payée ou pas
  - Nombre d'équipiers
- **CUF** = Cotisation (feature à décrire plus tard → ajouter dans les todos)

### Q9 - Données publiques : autorisation granulaire
**Réponse :**
- **Pseudo user :** TOUJOURS PUBLIC
- **Nom de radeau :** TOUJOURS PUBLIC
- **Photo user :** peut être publique ou non
  - Si publique : affichée partout
  - Si non publique : affichée seulement dans les équipes, le radeau de l'équipier, et aux admins
- **Pour les radeaux :** nom, photo, description → TOUS PUBLICS

### Q10 - "Matelot secret" : comptabilisé
**Réponse :**
- **Correction importante :** Le pseudo doit TOUJOURS être public (l'idée du pseudo privé était une erreur)
- **Matelots secrets** = matelots qui n'ont pas encore de pseudo
- **Affichage :** "matelot sans pseudonyme"
- **Comptabilisation :** OUI, comptés dans le nombre total de membres

### Q11 - Fichiers publics : upload ou liens
**Réponse :**
- **Principe général :** Liens externes seulement (pour alléger l'application)
- **Exception : PHOTOS**
  - Photos de radeau → stockées dans l'app
  - Photos de profil user → stockées dans l'app

---

## Features identifiées (à documenter)

1. **Inscription utilisateur**
   - Email valide obligatoire
   - Nom/prénom optionnel initialement (requis pour participation événement)
   - Pseudo possible
   - Coordonnées privées gérées plus tard

2. **Création d'équipage**
   - Tout user peut créer un équipage
   - Nom de radeau unique obligatoire
   - Créateur = gestionnaire initial

3. **Validation des nouveaux participants**
   - Statut "non validé" vs "validé"
   - Droits différenciés équipe validation vs admins
   - Validation par pseudo ou coordonnées

4. **Gestion d'équipage**
   - Nomination de gestionnaires
   - Ajout de membres
   - Gestion des demandes d'adhésion

5. **Rôles dans l'équipage**
   - Capitaine (nom peut changer)
   - Lead construction
   - Cuisine
   - Interlocuteur SAFE
   - Auto-déclaration vs attribution

6. **Page de login / redirection**
   - Membre d'équipage → page de son radeau
   - Non-membre → liste des radeaux

7. **Page publique de radeau**
   - Nom, description
   - Liste des membres (données publiques + "matelot secret")
   - Lien forum Discourse
   - Fichiers publics

8. **Page privée de radeau**
   - Visible par membres uniquement
   - Fonctions pour équipages (features à définir)

9. **Équipes transverses**
   - Modélisation similaire aux équipages
   - Visibilité restreinte (membres + admins)

10. **Validation admin des radeaux**
    - Badge "participant" vs "proposé"
    - Impact sur l'affichage/ordre dans les listes

11. **Gestion des bidons**
    - Ressource centralisée (seule de l'événement)
    - Permettent aux radeaux de flotter
    - En location (paiement nécessaire)
    - Demande après constitution et validation du radeau
    - Équipe bidon centralise, reçoit paiements, valide dans app

12. **CUF (Cotisation Urbaine Flottante)**
    - Cotisation pour participer à l'événement
    - Perçue par radeau (pas par personne)
    - Radeau déclare nombre de membres et paye pour ce nombre
    - Admin valide à réception du paiement
    - Nombre réel de membres peut temporairement différer
    - Régularisation nécessaire pour participation

---

## Feature détaillée : Gestion des bidons

### Contexte
- Bidons = seule ressource centralisée de l'événement
- En location (paiement hors app)
- Nécessaires pour faire flotter les radeaux

### Workflow
1. Radeau constitué et validé
2. Équipage statue du nombre de bidons nécessaires
3. **Demande de bidons** faite dans l'application
4. Équipe bidon centralise les demandes
5. Équipe bidon reçoit les paiements (hors application)
6. Équipe bidon **signale réception du paiement** dans l'application

### Données
- **Nombre de bidons demandés** : donnée publique
- **Statut de paiement** : donnée publique
- **Affichage :** Public mais pas affiché partout (sélectif)

### Interface et droits
- **Interface d'organisation pour les bidons :** accessible à tous
- **Validation de paiement :** réservée aux membres de l'équipe bidon + admins

### Réponses clarifications

**Q-BIDONS-1 - Qui peut faire la demande ?**
- **Tous les membres d'un équipage** peuvent faire la demande et/ou corriger le nombre
- **Une seule demande active** par radeau (mais demandes additionnelles possibles ensuite)
- **Historique** des paiements/demandes validées

**Q-BIDONS-2 - Modification de la demande**
- **Avant validation :** Modification possible à tout moment par :
  - Membre d'équipage
  - Membre équipe bidons
  - Admin
- **Après validation :** Demande additionnelle nécessaire
- Pas de remise pour le moment si besoin de moins de bidons (option en tête, discutée plus tard)

**Q-BIDONS-3 - Stock**
- **Stock limité**
- Bidons avec défauts découverts au début de l'événement
- **Gestion du stock :** Feature à discuter plus tard
- **Limites et priorités :** Gestion en discutant directement (pas par l'app)

**Q-BIDONS-4 - Montant et paiement**
- **Tarif par bidon** affiché dans l'app
- **Calcul automatique** du montant total pour chaque radeau sur leur page
- Valeur quasiment jamais changée
- **Changement possible :** en BDD ou par admin
- **Important :** Une fois "facture" payée, le montant ne bouge plus même si prix change
- **RIB** affiché dans l'app (sur la page "payer les bidons" ?)

**Q-BIDONS-5 - Statuts**
- Pour l'instant : **3 statuts**
  - Aucune demande faite
  - Demande en attente
  - Paiement validé
- Gestion du stock sur place discutée plus tard

**Q-BIDONS-6 - Radeau sans bidons**
- **Autorisé** (certains radeaux veulent autre mode de flottaison)
- Afficher **0 bidons** dans le nombre
- Organisateurs en discutent directement avec eux

---

## Feature détaillée : CUF (Cotisation Urbaine Flottante)

### Contexte
- CUF = cotisation pour participer à l'événement
- Version 2025 décrite sur Notion : https://carnetbleu.notion.site/Cotisation-Urbaine-Flottante-CUF-20dd51b5bb2280388646f0d8c7b51dd4
- **Perçue par radeau** (pas par personne individuelle)

### Workflow
1. Radeau déclare un nombre de membres
2. Radeau paye la CUF pour ce nombre de membres
3. Admin valide le nombre de membres à la réception du paiement

### Règles importantes
- **Flexibilité temporaire :** Un radeau peut avoir temporairement plus ou moins de membres que le nombre payé
- **Limite de participants :** Le nombre total de participants à l'événement est limité
- **Régularisation obligatoire :** Les participants sans CUF réglée ne pourront pas participer
- **Communication :** Être clair sur ce sujet dans la page du radeau

### Page admin - Récapitulatif
Afficher :
- Nombre total d'utilisateurs
- Nombre de membres/candidats pour des radeaux
- Nombre total de CUF payées

### Autre cotisation (non gérée dans l'app)
- **Cotisation à la base flottante** (dissociée de la CUF)
- Pas de gestion dans l'app pour le moment
- **Rappeler son existence** sur les pages importantes (ex: page radeau)
- Montant basé sur le nombre de nuits lors de la construction
- **TODO :** Afficher montant en fonction du nombre de nuits sur la base (à placer dans les todos)

### Réponses clarifications

**Q-CUF-1 - Qui déclare ?**
- **Le capitaine** (interface entre organisation et équipage)

**Q-CUF-2 - Modification et workflow**
- **CUF = inscription des participants** (nominatif)
- Déclaration des participants validés qui seront membres du radeau
- Changements possibles mais **validation admin nécessaire**
- Détails à préciser plus tard

**Statuts des membres d'un équipage :**
1. **Candidats** (ex: users non validés qui attendent entretien avec équipe accueil)
2. **Membres en attente de validation de participation**
3. **Participants** (CUF validée)
4. **Membres non participants** (ex: personnes non disponibles pour l'événement qui participent au travail en amont)

**Important :** Seul le capitaine est **obligatoirement un participant** (mais peut être capitaine avant d'être validé participant car arrive tard dans la timeline)

**Q-CUF-3 - Montant**
- **Montant fixe par personne**
- Sera fixé en Mars environ
- Affiché et calculé dans l'app

**Q-CUF-4 - Statuts**
- OK pour les statuts proposés
- Ajouter le statut **"non participant"**

**Q-CUF-5 - Affichage**
Sur la page équipage afficher :
- **Nombre de candidats** (seulement si il y en a)
- **Nombre de membres**
- **Nombre de participants validés** (CUF payée)
- **"CUF restant à régler"** (peut être négatif si désistement)

**Q-CUF-6 - Limite participants**
- Nombre limite **pas encore connu**
- Sera affiché dans la **page admin** avec le nombre de participants validés

**Q-CUF-7 - Cotisation base flottante**
- Feature à aborder plus tard
- Pour le moment : avoir en tête et préparer **placeholder sur la page du radeau**

---

## Clarifications supplémentaires - Session 2

### Unicité des équipages
- Un utilisateur ne peut être membre que d'**UN SEUL équipage** (pas de multi-appartenance)
- Il peut cependant être membre de **plusieurs équipes transverses**
- Un utilisateur ne peut créer un radeau que s'il **n'est pas déjà membre d'un équipage**
- Si il quitte son équipage, il peut ensuite créer un nouveau radeau

### Radeaux abandonnés
- Un radeau sans aucun membre = **radeau abandonné**
- Les admins peuvent l'effacer ou y affecter un nouveau membre (gestionnaire par défaut)

### Affichage du capitaine
- Le capitaine **n'est pas affiché publiquement** sur la page du radeau
- Il est affiché dans la **liste admin des radeaux** pour faciliter le contact

### Système d'éditions annuelles
**Changement majeur dans la structure :**
- Chaque événement Tutto Blu = une **édition** (année)
- Un radeau est **unique par édition** mais le nom peut être réutilisé d'une année sur l'autre
- Exemple : "Fun Radeau" peut exister en 2025, 2026, 2027 mais ce sont 3 radeaux différents
- **URL des radeaux :** `/[année]/radeaux/[nom]` (ex: `/2026/radeaux/fun-radeau`)
- **Règle d'unicité :** Nom unique **par édition** (pas globalement unique)
- **Table éditions :** Nécessaire pour gérer les différentes années
- Un équipage est lié à **une seule édition**
- Un radeau peut avoir un lien vers le radeau du même nom de l'édition précédente (historique)

### Équipes transverses - Adhésion
- **Pas de bouton "Rejoindre"** dans l'application
- Le recrutement se fait par **discussions externes** (WhatsApp, forum, en personne)
- Une fois validé, le coordinateur ajoute le membre directement dans l'app
- Les équipes sont en **nombre très limité** et gérées plutôt en dur dans le code

---

_Session complétée - Toutes les features documentées avec corrections_
