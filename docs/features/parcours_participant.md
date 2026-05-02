# Parcours participant

Ce document décrit le parcours complet d'un utilisateur, de la préinscription à la participation confirmée à l'édition.

## Vue d'ensemble

```
Création de compte
      ↓
[Admin] Qualification (flag "accueilli")
      ↓
[Admin] Attribution d'une CUF
      ↓
[Utilisateur] Achat de la CUF sur HelloAsso
      ↓
[Utilisateur] Validation des prérequis
      ↓
Participation confirmée
```

---

## Étapes détaillées

### 1. Préinscription — Création de compte

La création d'un compte sur l'application vaut préinscription à l'édition en cours.

Pour les éditions suivantes, un bouton **"Se réinscrire à l'édition"** sur la page de profil permettra de réinscrire un compte existant sans en recréer un. Les comptes sont conservés d'une année sur l'autre.

> **À préciser :** Fermeture des préinscriptions — à quel moment et comment l'application l'indique.

### 2. Qualification — Flag "accueilli"

Flag booléen géré par les administrateurs. Il indique que l'organisation a pris contact avec l'utilisateur et que celui-ci est au fait des spécificités de l'événement.

Ce flag est positionné manuellement par un admin. Il n'est pas automatique.

**Cas typiques :** membre d'une édition précédente, personne directement introduite par l'orga.

> **À préciser :** Ce flag a-t-il un impact fonctionnel (débloque des actions) ou est-il purement informatif pour les admins ?

### 3. Attribution de la CUF

**CUF : Cotisation Urbaine Flottante.** C'est le ticket d'entrée à l'événement — sans CUF, pas de participation possible.

Les CUF sont attribuées individuellement par un administrateur (une CUF par utilisateur). L'attribution se fait via l'application.

### 4. Achat de la CUF sur HelloAsso

Une fois attribuée, la CUF doit être achetée par l'utilisateur sur la plateforme **HelloAsso**.

L'application communiquera avec HelloAsso via leur API pour vérifier le statut d'achat. Ce point fera l'objet d'un développement spécifique.

Les CUF peuvent être **transférées** entre utilisateurs (par exemple en cas de changement de radeau ou d'abandon), soit via HelloAsso, soit via cette application en utilisant l'API.

> **À développer :** Intégration API HelloAsso (vérification d'achat, transferts).

### 5. Prérequis à la participation

La CUF achetée est nécessaire mais non suffisante. L'utilisateur doit valider un ensemble de prérequis.

| Prérequis | Vérification | Notes |
|---|---|---|
| CUF achetée | Automatique (HelloAsso) | Porte d'entrée obligatoire |
| Décharge de responsabilité | Auto-déclarée (bonne foi) | |
| Décharge capitaine | Auto-déclarée (bonne foi) | Uniquement si capitaine d'équipage |
| Paiement à la base de loisirs | À préciser | Modalités TBD |
| Acceptation dans un équipage | Automatique (application) | |

Les prérequis auto-déclarés reposent sur la bonne foi de l'utilisateur. L'application les présente à cocher sans pouvoir les vérifier objectivement.

> **À préciser :** Modalités du paiement à la base de loisirs (en ligne, sur place, vérifiable ?). Autres prérequis éventuels.

### 6. Participation confirmée

Un utilisateur est **participant confirmé** lorsque :
- Sa CUF est achetée (vérifié via HelloAsso)
- Tous les prérequis sont cochés

---

## Concepts clés

| Concept | Description |
|---|---|
| **CUF** (Cotisation Urbaine Flottante) | Ticket d'entrée à l'événement. Attribuée par l'admin, achetée sur HelloAsso. Transférable. |
| **Accueilli** | Flag admin : l'orga a contacté l'utilisateur, il connaît les spécificités de l'événement. |
| **Participant confirmé** | CUF achetée + tous prérequis validés. |
| **HelloAsso** | Plateforme de billetterie. API à intégrer pour la vérification des CUF. |

---

## Points ouverts

- [ ] Impact fonctionnel du flag "accueilli" (informatif ou débloquant ?)
- [ ] Fermeture des préinscriptions : comportement de l'application
- [ ] Décharges de responsabilité : signature en ligne ou hors ligne ?
- [ ] Paiement à la base de loisirs : modalités et vérifiabilité
- [ ] Intégration API HelloAsso
- [ ] Autres prérequis éventuels
