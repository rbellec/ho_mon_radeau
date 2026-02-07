# Console et manipulation des données

## Lancer la console IEx

```bash
# Depuis le répertoire du projet
docker compose exec app iex -S mix
```

## Manipulations utilisateurs

### Importer les modules nécessaires

```elixir
alias HoMonRadeau.{Accounts, Repo}
alias HoMonRadeau.Accounts.User
```

### Trouver un utilisateur

```elixir
# Par email
user = Accounts.get_user_by_email("email@example.com")

# Par ID
user = Accounts.get_user!(1)

# Lister tous les utilisateurs
Repo.all(User)
```

### Valider un utilisateur (validation équipe d'accueil)

```elixir
user = Accounts.get_user_by_email("email@example.com")
Accounts.validate_user(user)
```

### Invalider un utilisateur

```elixir
user = Accounts.get_user_by_email("email@example.com")
Accounts.invalidate_user(user)
```

### Passer un utilisateur admin

```elixir
user = Accounts.get_user_by_email("email@example.com")
user
|> Ecto.Changeset.change(is_admin: true)
|> Repo.update()
```

### Retirer les droits admin

```elixir
user = Accounts.get_user_by_email("email@example.com")
user
|> Ecto.Changeset.change(is_admin: false)
|> Repo.update()
```

### Confirmer manuellement un email (si besoin)

```elixir
user = Accounts.get_user_by_email("email@example.com")
user
|> User.confirm_changeset()
|> Repo.update()
```

## Manipulations radeaux et équipages

### Importer les modules

```elixir
alias HoMonRadeau.{Events, Repo}
alias HoMonRadeau.Events.{Raft, CrewMembership}
```

### Lister les radeaux

```elixir
Events.list_rafts()
```

### Ajouter un utilisateur à un équipage

```elixir
user = Accounts.get_user_by_email("email@example.com")
raft = Events.get_raft!(1)

Events.add_crew_member(raft, user, %{role: "equipier"})
# Rôles possibles: "capitaine", "second", "equipier"
```

### Retirer un membre d'équipage

```elixir
Events.remove_crew_member(raft, user)
```

### Voir l'équipage d'un radeau

```elixir
raft = Events.get_raft!(1) |> Repo.preload(:crew_members)
raft.crew_members
```

## Créer un jeu de données de test

Pour initialiser une base de données avec des données de test :

```bash
docker compose exec app mix run priv/repo/seeds_dev.exs
```

Ou depuis IEx :

```elixir
Code.require_file("priv/repo/seeds_dev.exs")
```

## Quitter la console

```elixir
# Ctrl+C deux fois, ou :
System.halt()
```
