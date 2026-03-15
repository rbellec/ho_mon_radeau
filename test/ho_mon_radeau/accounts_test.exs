defmodule HoMonRadeau.AccountsTest do
  use HoMonRadeau.DataCase

  alias HoMonRadeau.Accounts

  import HoMonRadeau.AccountsFixtures
  alias HoMonRadeau.Accounts.{User, UserToken}

  describe "get_user_by_email/1" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email("unknown@example.com")
    end

    test "returns the user if the email exists" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user_by_email(user.email)
    end
  end

  describe "get_user_by_email_and_password/2" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the user if the password is not valid" do
      user = user_fixture() |> set_password()
      refute Accounts.get_user_by_email_and_password(user.email, "invalid")
    end

    test "returns the user if the email and password are valid" do
      %{id: id} = user = user_fixture() |> set_password()

      assert %User{id: ^id} =
               Accounts.get_user_by_email_and_password(user.email, valid_user_password())
    end
  end

  describe "get_user!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!(-1)
      end
    end

    test "returns the user with the given id" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user!(user.id)
    end
  end

  describe "register_user/1" do
    test "requires email to be set" do
      {:error, changeset} = Accounts.register_user(%{})

      assert %{email: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates email when given" do
      {:error, changeset} = Accounts.register_user(%{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum values for email for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_user(%{email: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness" do
      %{email: email} = user_fixture()
      {:error, changeset} = Accounts.register_user(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the uppercased email too, to check that email case is ignored.
      {:error, changeset} = Accounts.register_user(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers users with password" do
      email = unique_user_email()
      {:ok, user} = Accounts.register_user(valid_user_attributes(email: email))
      assert user.email == email
      assert user.hashed_password
      assert is_nil(user.confirmed_at)
      assert is_nil(user.password)
    end
  end

  describe "sudo_mode?/2" do
    test "validates the authenticated_at time" do
      now = DateTime.utc_now()

      assert Accounts.sudo_mode?(%User{authenticated_at: DateTime.utc_now()})
      assert Accounts.sudo_mode?(%User{authenticated_at: DateTime.add(now, -19, :minute)})
      refute Accounts.sudo_mode?(%User{authenticated_at: DateTime.add(now, -21, :minute)})

      # minute override
      refute Accounts.sudo_mode?(
               %User{authenticated_at: DateTime.add(now, -11, :minute)},
               -10
             )

      # not authenticated
      refute Accounts.sudo_mode?(%User{})
    end
  end

  describe "change_user_email/3" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_email(%User{})
      assert changeset.required == [:email]
    end
  end

  describe "deliver_user_update_email_instructions/3" do
    setup do
      %{user: user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(user, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "change:current@example.com"
    end
  end

  describe "update_user_email/2" do
    setup do
      user = unconfirmed_user_fixture()
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{user: user, token: token, email: email}
    end

    test "updates the email with a valid token", %{user: user, token: token, email: email} do
      assert {:ok, %{email: ^email}} = Accounts.update_user_email(user, token)
      changed_user = Repo.get!(User, user.id)
      assert changed_user.email != user.email
      assert changed_user.email == email
      refute Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email with invalid token", %{user: user} do
      assert Accounts.update_user_email(user, "oops") ==
               {:error, :transaction_aborted}

      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if user email changed", %{user: user, token: token} do
      assert Accounts.update_user_email(%{user | email: "current@example.com"}, token) ==
               {:error, :transaction_aborted}

      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])

      assert Accounts.update_user_email(user, token) ==
               {:error, :transaction_aborted}

      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "change_user_password/3" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_password(%User{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Accounts.change_user_password(
          %User{},
          %{
            "password" => "new valid password"
          },
          hash_password: false
        )

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_user_password/2" do
    setup do
      %{user: user_fixture()}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_password(user, %{
          password: "short",
          password_confirmation: "other"
        })

      assert %{
               password: [
                 "le mot de passe doit faire 6 caractères minimum et un peu de folie. Un peu plus."
               ],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.update_user_password(user, %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{user: user} do
      {:ok, {user, expired_tokens}} =
        Accounts.update_user_password(user, %{
          password: "new valid password"
        })

      assert expired_tokens == []
      assert is_nil(user.password)
      assert Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "deletes all tokens for the given user", %{user: user} do
      _ = Accounts.generate_user_session_token(user)

      {:ok, {_, _}} =
        Accounts.update_user_password(user, %{
          password: "new valid password"
        })

      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "generate_user_session_token/1" do
    setup do
      %{user: user_fixture()}
    end

    test "generates a token", %{user: user} do
      token = Accounts.generate_user_session_token(user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.context == "session"
      assert user_token.authenticated_at != nil

      # Creating the same token for another user should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%UserToken{
          token: user_token.token,
          user_id: user_fixture().id,
          context: "session"
        })
      end
    end

    test "duplicates the authenticated_at of given user in new token", %{user: user} do
      user = %{user | authenticated_at: DateTime.add(DateTime.utc_now(:second), -3600)}
      token = Accounts.generate_user_session_token(user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.authenticated_at == user.authenticated_at
      assert DateTime.compare(user_token.inserted_at, user.authenticated_at) == :gt
    end
  end

  describe "get_user_by_session_token/1" do
    setup do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      %{user: user, token: token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert {session_user, token_inserted_at} = Accounts.get_user_by_session_token(token)
      assert session_user.id == user.id
      assert session_user.authenticated_at != nil
      assert token_inserted_at != nil
    end

    test "does not return user for invalid token" do
      refute Accounts.get_user_by_session_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      dt = ~N[2020-01-01 00:00:00]
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: dt, authenticated_at: dt])
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "get_user_by_magic_link_token/1" do
    setup do
      user = user_fixture()
      {encoded_token, _hashed_token} = generate_user_magic_link_token(user)
      %{user: user, token: encoded_token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert session_user = Accounts.get_user_by_magic_link_token(token)
      assert session_user.id == user.id
    end

    test "does not return user for invalid token" do
      refute Accounts.get_user_by_magic_link_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_user_by_magic_link_token(token)
    end
  end

  describe "login_user_by_magic_link/1" do
    test "returns user and (deleted) token for confirmed user" do
      user = user_fixture()
      assert user.confirmed_at
      {encoded_token, _hashed_token} = generate_user_magic_link_token(user)
      assert {:ok, {^user, []}} = Accounts.login_user_by_magic_link(encoded_token)
      # one time use only
      assert {:error, :not_found} = Accounts.login_user_by_magic_link(encoded_token)
    end

    test "confirms unconfirmed user with password and returns :confirmed_with_password" do
      user = unconfirmed_user_fixture()
      # Our users always have passwords after registration
      assert user.hashed_password
      refute user.confirmed_at
      {encoded_token, _hashed_token} = generate_user_magic_link_token(user)

      assert {:ok, :confirmed_with_password, confirmed_user} =
               Accounts.login_user_by_magic_link(encoded_token)

      assert confirmed_user.id == user.id
      assert confirmed_user.confirmed_at
    end
  end

  describe "delete_user_session_token/1" do
    test "deletes the token" do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      assert Accounts.delete_user_session_token(token) == :ok
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "deliver_login_instructions/2" do
    setup do
      %{user: unconfirmed_user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_login_instructions(user, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "login"
    end
  end

  describe "inspect/2 for the User module" do
    test "does not include password" do
      refute inspect(%User{password: "123456"}) =~ "password: \"123456\""
    end
  end

  describe "get_user/1" do
    test "returns nil when user does not exist" do
      assert Accounts.get_user(-1) == nil
    end

    test "returns the user when it exists" do
      %{id: id} = user_fixture()
      assert %User{id: ^id} = Accounts.get_user(id)
    end
  end

  describe "display_name/1" do
    test "returns nickname when present" do
      assert Accounts.display_name(%User{nickname: "Captain Hook"}) == "Captain Hook"
    end

    test "returns default when nickname is nil" do
      assert Accounts.display_name(%User{nickname: nil}) == "matelot sans pseudonyme"
    end

    test "returns default when nickname is empty string" do
      assert Accounts.display_name(%User{nickname: ""}) == "matelot sans pseudonyme"
    end
  end

  describe "validate_user/1" do
    test "marks a user as validated" do
      user = user_fixture()
      assert {:ok, validated_user} = Accounts.validate_user(user)
      assert validated_user.validated == true
    end
  end

  describe "invalidate_user/1" do
    test "revokes user validation" do
      user = user_fixture()
      {:ok, validated_user} = Accounts.validate_user(user)
      assert validated_user.validated == true

      assert {:ok, invalidated_user} = Accounts.invalidate_user(validated_user)
      assert invalidated_user.validated == false
    end
  end

  describe "list_pending_validation_users/0" do
    test "returns confirmed but not validated users" do
      confirmed_user = user_fixture()
      # confirmed_user is confirmed but not validated by default
      results = Accounts.list_pending_validation_users()
      assert Enum.any?(results, fn u -> u.id == confirmed_user.id end)
    end

    test "excludes unconfirmed users" do
      _unconfirmed = unconfirmed_user_fixture()
      confirmed_user = user_fixture()

      results = Accounts.list_pending_validation_users()
      assert Enum.any?(results, fn u -> u.id == confirmed_user.id end)
      refute Enum.any?(results, fn u -> u.confirmed_at == nil end)
    end

    test "excludes validated users" do
      user = user_fixture()
      {:ok, _validated} = Accounts.validate_user(user)

      results = Accounts.list_pending_validation_users()
      refute Enum.any?(results, fn u -> u.id == user.id end)
    end
  end

  describe "list_validated_users/0" do
    test "returns only validated users" do
      user = user_fixture()
      {:ok, validated_user} = Accounts.validate_user(user)
      _non_validated = user_fixture()

      results = Accounts.list_validated_users()
      assert Enum.any?(results, fn u -> u.id == validated_user.id end)
      assert Enum.all?(results, fn u -> u.validated == true end)
    end
  end

  describe "list_all_users/0" do
    test "returns all confirmed users" do
      confirmed = user_fixture()
      _unconfirmed = unconfirmed_user_fixture()

      results = Accounts.list_all_users()
      assert Enum.any?(results, fn u -> u.id == confirmed.id end)
      refute Enum.any?(results, fn u -> u.confirmed_at == nil end)
    end
  end

  describe "search_users/1" do
    test "matches users by email" do
      user = user_fixture()
      # Extract a portion of the email to search
      [local_part, _] = String.split(user.email, "@")
      results = Accounts.search_users(local_part)
      assert Enum.any?(results, fn u -> u.id == user.id end)
    end

    test "matches users by nickname" do
      user = user_fixture()
      {:ok, user} = Accounts.update_user_profile(user, %{nickname: "SailorMoon"})

      results = Accounts.search_users("SailorMoon")
      assert Enum.any?(results, fn u -> u.id == user.id end)
    end

    test "excludes unconfirmed users" do
      unconfirmed = unconfirmed_user_fixture()
      [local_part, _] = String.split(unconfirmed.email, "@")

      results = Accounts.search_users(local_part)
      refute Enum.any?(results, fn u -> u.id == unconfirmed.id end)
    end

    test "limits results to 10" do
      for _ <- 1..12,
          do: user_fixture(%{email: "searchlimit_#{System.unique_integer()}@test.com"})

      results = Accounts.search_users("searchlimit_")
      assert length(results) <= 10
    end
  end

  describe "can_participate?/1" do
    test "returns false if user is not validated" do
      refute Accounts.can_participate?(%User{validated: false, first_name: "A", last_name: "B"})
    end

    test "returns false if first_name is nil" do
      refute Accounts.can_participate?(%User{validated: true, first_name: nil, last_name: "B"})
    end

    test "returns false if last_name is nil" do
      refute Accounts.can_participate?(%User{validated: true, first_name: "A", last_name: nil})
    end

    test "returns false if first_name is empty" do
      refute Accounts.can_participate?(%User{validated: true, first_name: "", last_name: "B"})
    end

    test "returns false if last_name is empty" do
      refute Accounts.can_participate?(%User{validated: true, first_name: "A", last_name: ""})
    end

    test "returns true if validated with both names" do
      assert Accounts.can_participate?(%User{validated: true, first_name: "A", last_name: "B"})
    end
  end

  describe "update_user_profile/2" do
    test "updates profile with valid data" do
      user = user_fixture()

      assert {:ok, updated} =
               Accounts.update_user_profile(user, %{
                 nickname: "NewNick",
                 first_name: "Jean",
                 last_name: "Dupont"
               })

      assert updated.nickname == "NewNick"
      assert updated.first_name == "Jean"
      assert updated.last_name == "Dupont"
    end

    test "returns error with invalid data" do
      user = user_fixture()
      # nickname too short (min 2 chars)
      assert {:error, changeset} = Accounts.update_user_profile(user, %{nickname: "A"})
      assert errors_on(changeset).nickname != []
    end
  end

  describe "change_user_profile/2" do
    test "returns a changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user_profile(user, %{nickname: "Test"})
    end
  end
end
