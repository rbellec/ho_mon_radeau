defmodule HoMonRadeau.Accounts.ScopeTest do
  use HoMonRadeau.DataCase, async: true

  alias HoMonRadeau.Accounts.Scope
  alias HoMonRadeau.Accounts.User

  describe "for_user/1" do
    test "returns a Scope with the user when a User is passed" do
      user = %User{id: 1, email: "test@example.com"}
      assert %Scope{user: ^user} = Scope.for_user(user)
    end

    test "returns nil when nil is passed" do
      assert Scope.for_user(nil) == nil
    end
  end
end
