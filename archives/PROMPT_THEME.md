# Ralph Loop — Migration thème Assan

Tu es un développeur Elixir/Phoenix spécialisé frontend qui migre l'UI de **HoMonRadeau** du thème daisyUI vers le thème **Assan Multipurpose Template v5.8** (variante TailwindCSS 4).

## Contexte

- Lis `CLAUDE.md` pour les conventions (langue, nommage, stack)
- Lis `AGENTS.md` pour les règles Phoenix/LiveView/HEEx impératives
- Le thème source est dans `assan_multipurpose_template_v5.8/tailwindcss4/main-tailwindcss/`
- Branche de travail : `adapt_theme`

## Critère de vérification

À chaque itération, lance :

```bash
docker compose run --rm -e MIX_ENV=test app mix precommit
```

**Si ça échoue** → corriger avant de continuer.
**Si ça passe** → passer à la phase suivante.

## Source du thème Assan

```
assan_multipurpose_template_v5.8/tailwindcss4/main-tailwindcss/
├── src/css/style.css          ← CSS custom Assan (à intégrer)
├── src/js/theme.js            ← JS Assan (ne pas tout prendre)
├── src/js/custom/             ← Modules JS individuels
├── public/                    ← Pages HTML de référence
│   ├── header-default.html    ← Structure header/navbar
│   ├── footer-1.html          ← Footer simple
│   ├── page-account-signin.html    ← Login
│   ├── page-account-signup.html    ← Inscription
│   ├── index-landing-startup.html  ← Landing page
│   └── component-card-icon.html    ← Cards
└── public/assets/
    ├── css/style.css          ← CSS compilé
    ├── fonts/                 ← Fonts (bootstrap-icons, etc.)
    └── vendor/                ← Libs JS vendor
```

## Ce qu'on garde de l'existant

- **Heroicons** (déjà intégrés, ne pas remplacer par Bootstrap Icons)
- **Toute la logique Elixir/LiveView** (ne toucher qu'aux templates HEEx et au CSS)
- **La structure des fichiers** (`core_components.ex`, layouts, LiveViews)
- **Les tests existants** (ne pas les casser)

## Ce qu'on NE fait PAS

- Pas de GSAP / animations complexes
- Pas de Swiper / parallax / particles / jQuery
- Pas de dark mode (light only)
- Pas de Bootstrap Icons (garder Heroicons)
- Pas de preloader

## Phases d'implémentation

### Phase 1 — Fondations CSS

1. **Remplacer daisyUI par Assan CSS** dans `assets/css/app.css` :
   - Retirer les plugins daisyUI et daisyui-theme
   - Intégrer le contenu de `src/css/style.css` d'Assan (les classes custom)
   - Garder les imports Tailwind, heroicons, et les variantes LiveView (`phx-click-loading`, etc.)
   - Ajouter les fonts Google (DM Sans) via un import ou un lien dans `root.html.heex`
   - Définir la palette de couleurs Assan (slate, indigo, etc.) dans les variables CSS

2. **Vérifier la compilation** : `docker compose run --rm -e MIX_ENV=test app mix precommit`
   - L'app doit compiler et les tests passer, même si le visuel est cassé temporairement

3. **Commit** : `Replace daisyUI with Assan CSS foundation`

### Phase 2 — Layout (header + footer)

1. **Adapter `root.html.heex`** en s'inspirant de `header-default.html` d'Assan :
   - Navbar avec logo, liens de navigation, menu mobile
   - Dropdowns pour admin et profil utilisateur
   - Style Assan : fond blanc/transparent, liens sombres, hover underline
   - **Garder les mêmes liens et la même logique conditionnelle** (admin, authenticated, etc.)
   - Supprimer le toggle dark mode

2. **Ajouter un footer** inspiré de `footer-1.html` d'Assan :
   - Simple, sobre, avec copyright
   - Peut être ajouté dans le layout `app` de `layouts.ex`

3. **Adapter la fonction `app` dans `layouts.ex`** :
   - Retirer le `flash_group` inline (le placer correctement)
   - Adapter le wrapper pour la structure Assan (container, padding, etc.)

4. **Commit** : `Adapt layout with Assan header and footer`

### Phase 3 — Core Components

Adapter `core_components.ex`. **C'est le fichier le plus important** — tous les templates l'utilisent.

Pour chaque composant, s'inspirer des classes trouvées dans les pages HTML Assan. Consulter :
- `page-account-signin.html` pour les inputs et boutons
- `component-form-components.html` pour les formulaires
- `component-buttons.html` pour les variantes de boutons
- `component-alerts.html` pour les alertes
- `component-card-icon.html` pour les cards

Composants à adapter (un par un, tester entre chaque) :

1. **`.button`** : Remplacer `btn btn-primary` etc. par les classes Assan (`bg-indigo-600 text-white rounded-lg px-5 py-2.5 hover:bg-indigo-700 transition`, etc.)
2. **`.input`** : Remplacer les classes daisyUI par les classes Assan (`.input` class du style.css Assan)
3. **`.flash`** : Remplacer `alert alert-info` par les alertes Assan (fond coloré + icône + texte)
4. **`.header`** : Adapter le composant header (titre + subtitle + actions)
5. **`.table`** : Adapter les styles de table
6. **`.modal`** : Si utilisé, adapter le style modal
7. **`.icon`** : Garder tel quel (Heroicons)

**Attention** : Les composants `<.input>`, `<.button>`, `<.form>` sont utilisés partout. Changer leurs classes ici met à jour toutes les pages d'un coup.

**Commit** : `Adapt core components to Assan theme`

### Phase 4 — Pages d'authentification

Adapter les templates dans `lib/ho_mon_radeau_web/controllers/` :

1. **`user_session_html/new.html.heex`** (login) → s'inspirer de `page-account-signin.html`
2. **`user_registration_html/new.html.heex`** (inscription) → s'inspirer de `page-account-signup.html`
3. **`user_settings_html/edit.html.heex`** (paramètres) → formulaire cohérent
4. **`user_session_html/confirm.html.heex`** (magic link) → formulaire cohérent

**Commit** : `Restyle authentication pages with Assan theme`

### Phase 5 — Page d'accueil et landing

Adapter `lib/ho_mon_radeau_web/controllers/page_html/home.html.heex` :

- S'inspirer de `index-landing-startup.html` ou `index-landing-classic.html`
- Hero section avec titre, description de l'événement
- Section features/avantages
- Call to action (inscription / connexion)
- La page est différente selon que l'utilisateur est connecté ou non (garder la logique existante)

**Commit** : `Restyle landing page with Assan theme`

### Phase 6 — Pages publiques (radeaux)

Adapter les LiveViews dans `lib/ho_mon_radeau_web/live/raft_live/` :

1. **`index.ex`** — Liste des radeaux : cards Assan, badges statut, bouton créer
2. **`show.ex`** — Page publique d'un radeau : layout Assan, infos, membres, bouton rejoindre
3. **`new.ex`** — Formulaire de création : formulaire Assan cohérent

**Commit** : `Restyle public raft pages with Assan theme`

### Phase 7 — Pages privées et profil

1. **`my_crew.ex`** — Page privée du radeau : cards, roles, bidons, CUF, membres
2. **`profile_live.ex`** — Profil utilisateur : formulaire, badges, liens
3. **`registration_form_live/index.ex`** — Fiche d'inscription : upload, statut

**Commit** : `Restyle private crew and profile pages with Assan theme`

### Phase 8 — Pages admin

Adapter les LiveViews dans `lib/ho_mon_radeau_web/live/admin/` :

1. **`user_live/index.ex`** + **`show.ex`** — Gestion utilisateurs
2. **`raft_live/index.ex`** — Gestion radeaux
3. **`registration_form_live/index.ex`** + **`show.ex`** — Fiches d'inscription
4. **`transverse_team_live/index.ex`** + **`show.ex`** — Équipes transverses
5. **`drums_live/index.ex`** — Bidons
6. **`cuf_live/index.ex`** — CUF
7. **`departures_live.ex`** — Départs

**Commit** : `Restyle admin pages with Assan theme`

## Principes de style Assan à appliquer

### Couleurs principales (palette par défaut Assan)
- **Primaire** : indigo-600 (`#4F46E5`) — boutons, liens, accents
- **Fond page** : blanc ou slate-50
- **Texte** : slate-900 (titres), slate-600 (corps), slate-400 (secondaire)
- **Cards** : fond blanc, `shadow-sm` ou `shadow-md`, `rounded-xl`
- **Succès** : green-500 / green-600
- **Warning** : amber-500
- **Erreur** : red-500 / red-600

### Typographie
- Font sans-serif : `DM Sans`
- Titres : font-semibold ou font-bold, tailles généreuses
- Corps : text-base ou text-sm, line-height relaxed

### Boutons
- Primaire : `bg-indigo-600 text-white rounded-lg px-5 py-2.5 font-medium hover:bg-indigo-700 transition`
- Secondaire/Ghost : `text-indigo-600 hover:bg-indigo-50 rounded-lg px-5 py-2.5`
- Small : `text-sm px-3 py-1.5`
- Danger : `bg-red-600 text-white hover:bg-red-700`

### Cards
- `bg-white rounded-xl shadow-sm border border-slate-200 p-6`
- Hover : `hover:shadow-md transition-shadow`

### Formulaires
- Labels : `text-sm font-medium text-slate-700 mb-1`
- Inputs : `w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500`
- Erreur : `border-red-500 focus:border-red-500 focus:ring-red-500`

### Badges
- Succès : `bg-green-100 text-green-700 text-xs font-medium px-2.5 py-0.5 rounded-full`
- Warning : `bg-amber-100 text-amber-700 ...`
- Info : `bg-indigo-100 text-indigo-700 ...`
- Ghost : `bg-slate-100 text-slate-600 ...`

### Alertes
- Info : `bg-indigo-50 border border-indigo-200 text-indigo-800 rounded-xl p-4`
- Warning : `bg-amber-50 border border-amber-200 text-amber-800 rounded-xl p-4`
- Error : `bg-red-50 border border-red-200 text-red-800 rounded-xl p-4`

### Tables
- Header : `bg-slate-50 text-slate-500 text-xs font-medium uppercase`
- Rows : `border-b border-slate-100 hover:bg-slate-50`
- Cells : `px-4 py-3 text-sm`

### Navbar (header)
- `bg-white shadow-sm border-b border-slate-200`
- Liens : `text-slate-700 hover:text-indigo-600 font-medium text-sm`
- Dropdown : `bg-white shadow-lg rounded-xl border border-slate-200`

## Condition d'arrêt

Quand **les 8 phases sont terminées**, que `mix precommit` passe, et que le thème est visuellement cohérent :

```
<promise>THEME MIGRATION COMPLETE</promise>
```

## Notes importantes

- Les commandes s'exécutent dans Docker : `docker compose run --rm app mix...`
- Ne modifier QUE les templates (`.heex`), `core_components.ex`, `layouts.ex`, et `app.css`
- Ne pas toucher à la logique métier (contextes, schemas, router)
- Ne pas modifier les tests sauf si une modification de composant change le HTML attendu
- Utiliser `current_scope.user` (jamais `current_user`) dans les templates Phoenix 1.8
- Consulter les fichiers HTML Assan dans `assan_multipurpose_template_v5.8/tailwindcss4/main-tailwindcss/public/` comme référence visuelle
- Quand un composant dans `core_components.ex` est modifié, vérifier que toutes les pages qui l'utilisent restent cohérentes
