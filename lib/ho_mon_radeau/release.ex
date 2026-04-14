defmodule HoMonRadeau.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :ho_mon_radeau

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  @doc """
  Creates the first admin user, or promotes an existing user to admin.

  Usage in production:
    /app/bin/ho_mon_radeau eval "HoMonRadeau.Release.create_admin(\"email@example.com\")"
  """
  def create_admin(email) do
    load_app()

    {:ok, _, _} =
      Ecto.Migrator.with_repo(HoMonRadeau.Repo, fn repo ->
        case repo.get_by(HoMonRadeau.Accounts.User, email: email) do
          nil ->
            # Create a new admin user with a random password (use magic link to log in)
            password = :crypto.strong_rand_bytes(32) |> Base.url_encode64()

            {:ok, user} =
              HoMonRadeau.Accounts.register_user(%{
                email: email,
                password: password
              })

            user
            |> Ecto.Changeset.change(%{
              is_admin: true,
              validated: true,
              confirmed_at: DateTime.utc_now(:second)
            })
            |> repo.update!()

            IO.puts("Admin user created: #{email} (use magic link to log in)")

          user ->
            user
            |> Ecto.Changeset.change(%{is_admin: true, validated: true})
            |> repo.update!()

            IO.puts("User promoted to admin: #{email}")
        end
      end)
  end

  @doc """
  Resets a user's password.

  Usage in production:
    /app/bin/ho_mon_radeau eval "HoMonRadeau.Release.reset_password(\"email@example.com\", \"new_password\")"
  """
  def reset_password(email, new_password) do
    load_app()

    {:ok, _, _} =
      Ecto.Migrator.with_repo(HoMonRadeau.Repo, fn repo ->
        case repo.get_by(HoMonRadeau.Accounts.User, email: email) do
          nil ->
            IO.puts("Error: user not found: #{email}")

          user ->
            user
            |> Ecto.Changeset.change(%{
              hashed_password: Bcrypt.hash_pwd_salt(new_password)
            })
            |> repo.update!()

            IO.puts("Password reset for: #{email}")
        end
      end)
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    # Many platforms require SSL when connecting to the database
    Application.ensure_all_started(:ssl)
    Application.ensure_loaded(@app)
  end
end
