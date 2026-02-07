# Development seeds - creates test data for local development
#
# Run with:
#   docker compose exec app mix run priv/repo/seeds_dev.exs
#
# WARNING: This will create users with known passwords!
# Only use in development environments.

alias HoMonRadeau.{Repo, Accounts, Events}
alias HoMonRadeau.Accounts.User
alias HoMonRadeau.Events.{Edition, Raft, Crew, CrewMember}

IO.puts("Creating development seed data...")

# Helper to create a confirmed user
create_user = fn email, nickname, opts ->
  password = Keyword.get(opts, :password, "password123")
  is_admin = Keyword.get(opts, :is_admin, false)
  validated = Keyword.get(opts, :validated, false)
  first_name = Keyword.get(opts, :first_name)
  last_name = Keyword.get(opts, :last_name)

  case Accounts.get_user_by_email(email) do
    nil ->
      {:ok, user} = Accounts.register_user(%{
        email: email,
        password: password,
        nickname: nickname
      })

      # Confirm the user
      {:ok, user} = user
        |> Ecto.Changeset.change(%{
          confirmed_at: DateTime.utc_now(:second),
          is_admin: is_admin,
          validated: validated,
          first_name: first_name,
          last_name: last_name
        })
        |> Repo.update()

      IO.puts("  Created user: #{email} (#{nickname})")
      user

    user ->
      IO.puts("  User already exists: #{email}")
      user
  end
end

# Create admin user
admin = create_user.("admin@tuttoblu.test", "Capitaine Admin", [
  is_admin: true,
  validated: true,
  first_name: "Admin",
  last_name: "Tuttoblu"
])

# Create some regular validated users
user1 = create_user.("marin1@example.com", "Marin du Sud", [
  validated: true,
  first_name: "Jean",
  last_name: "Valjean"
])

user2 = create_user.("marin2@example.com", "Moussaillon", [
  validated: true,
  first_name: "Marie",
  last_name: "Curie"
])

user3 = create_user.("marin3@example.com", "Loup de Mer", [
  validated: true,
  first_name: "Victor",
  last_name: "Hugo"
])

user4 = create_user.("marin4@example.com", "Corsaire", [
  validated: true,
  first_name: "Alexandre",
  last_name: "Dumas"
])

# Create some unvalidated users (pending validation)
pending1 = create_user.("nouveau1@example.com", "NouveauVenu", [
  validated: false,
  first_name: "Pierre",
  last_name: "Nouveau"
])

pending2 = create_user.("nouveau2@example.com", "Debutant", [
  validated: false
])

# Create current edition
IO.puts("\nCreating edition...")
{:ok, edition} = case Events.get_current_edition() do
  nil ->
    Events.get_or_create_current_edition()
  edition ->
    IO.puts("  Edition already exists: #{edition.name}")
    {:ok, edition}
end

IO.puts("  Edition: #{edition.name}")

# Create rafts with crews
IO.puts("\nCreating rafts and crews...")

create_raft_with_crew = fn name, description, captain, members ->
  case Repo.get_by(Raft, name: name, edition_id: edition.id) do
    nil ->
      {:ok, %{raft: raft, crew: crew}} = Events.create_raft_with_crew(captain, %{
        name: name,
        description: description,
        description_short: String.slice(description, 0, 100)
      }, edition.id)

      IO.puts("  Created raft: #{name}")

      # Add additional crew members
      Enum.each(members, fn {user, opts} ->
        is_manager = Keyword.get(opts, :is_manager, false)
        roles = Keyword.get(opts, :roles, [])

        {:ok, _} = Events.add_crew_member(crew.id, user.id, %{
          is_manager: is_manager,
          roles: roles,
          participation_status: "confirmed"
        })
        IO.puts("    Added crew member: #{user.nickname || user.email}")
      end)

      raft

    raft ->
      IO.puts("  Raft already exists: #{name}")
      raft
  end
end

# Raft 1: Le Radeau de la Meduse
create_raft_with_crew.(
  "Le Radeau de la Meduse",
  "Un radeau mythique, construit avec passion et determination. Notre equipage est pret pour l'aventure!",
  user1,
  [
    {user2, [is_manager: true, roles: ["cooking", "decoration"]]},
    {user3, [roles: ["music"]]}
  ]
)

# Raft 2: Les Flibustiers
create_raft_with_crew.(
  "Les Flibustiers",
  "Pirates des temps modernes, nous naviguons vers la liberte!",
  admin,
  [
    {user4, [is_manager: true, roles: ["lead_construction", "logistics"]]}
  ]
)

# Raft 3: L'Odyssee (just the captain, small crew)
create_raft_with_crew.(
  "L'Odyssee",
  "Petit radeau mais grandes ambitions. Un voyage epique nous attend.",
  user4,
  []
)

IO.puts("\n--- Development seed data created! ---")
IO.puts("\nTest accounts:")
IO.puts("  Admin: admin@tuttoblu.test / password123")
IO.puts("  Users: marin1@example.com, marin2@example.com, etc. / password123")
IO.puts("\nRafts created: Le Radeau de la Meduse, Les Flibustiers, L'Odyssee")
