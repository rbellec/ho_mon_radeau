defmodule HoMonRadeau.EventsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HoMonRadeau.Events` context.
  """

  import HoMonRadeau.AccountsFixtures

  alias HoMonRadeau.Repo
  alias HoMonRadeau.Events

  alias HoMonRadeau.Events.{
    Raft,
    Crew,
    CrewMember,
    CrewJoinRequest,
    RaftLink,
    RegistrationForm,
    CrewDeparture
  }

  def unique_year, do: 2100 + rem(System.unique_integer([:positive]), 800)

  def edition_fixture(attrs \\ %{}) do
    {:ok, edition} =
      attrs
      |> Enum.into(%{
        year: unique_year(),
        name: "Test Edition #{System.unique_integer([:positive])}",
        is_current: true
      })
      |> Events.create_edition()

    edition
  end

  def raft_fixture(attrs \\ %{}) do
    edition = Map.get_lazy(attrs, :edition, fn -> edition_fixture() end)

    %Raft{}
    |> Raft.changeset(
      attrs
      |> Map.drop([:edition])
      |> Enum.into(%{
        name: "Test Raft #{System.unique_integer([:positive])}",
        edition_id: edition.id
      })
    )
    |> Repo.insert!()
  end

  def raft_with_crew_fixture(attrs \\ %{}) do
    user = Map.get_lazy(attrs, :user, fn -> user_fixture() end)
    edition = Map.get_lazy(attrs, :edition, fn -> edition_fixture() end)

    raft_attrs =
      attrs
      |> Map.drop([:user, :edition])
      |> Enum.into(%{
        name: "Test Raft #{System.unique_integer([:positive])}"
      })

    {:ok, raft} = Events.create_raft_with_crew(user, raft_attrs, edition.id)
    raft
  end

  def crew_fixture(attrs \\ %{}) do
    edition = Map.get_lazy(attrs, :edition, fn -> edition_fixture() end)
    raft = Map.get_lazy(attrs, :raft, fn -> raft_fixture(%{edition: edition}) end)

    %Crew{}
    |> Crew.changeset(
      attrs
      |> Map.drop([:edition, :raft])
      |> Enum.into(%{
        raft_id: raft.id,
        edition_id: edition.id
      })
    )
    |> Repo.insert!()
  end

  def crew_member_fixture(attrs \\ %{}) do
    user = Map.get_lazy(attrs, :user, fn -> user_fixture() end)
    crew = Map.get_lazy(attrs, :crew, fn -> crew_fixture() end)

    %CrewMember{}
    |> CrewMember.changeset(
      attrs
      |> Map.drop([:user, :crew])
      |> Enum.into(%{
        crew_id: crew.id,
        user_id: user.id,
        is_manager: false,
        is_captain: false
      })
    )
    |> Repo.insert!()
  end

  def join_request_fixture(attrs \\ %{}) do
    user = Map.get_lazy(attrs, :user, fn -> user_fixture() end)
    crew = Map.get_lazy(attrs, :crew, fn -> crew_fixture() end)

    %CrewJoinRequest{}
    |> CrewJoinRequest.changeset(
      attrs
      |> Map.drop([:user, :crew])
      |> Enum.into(%{
        crew_id: crew.id,
        user_id: user.id,
        message: "I'd like to join!"
      })
    )
    |> Repo.insert!()
  end

  def raft_link_fixture(attrs \\ %{}) do
    raft = Map.get_lazy(attrs, :raft, fn -> raft_fixture() end)

    %RaftLink{}
    |> RaftLink.changeset(
      attrs
      |> Map.drop([:raft])
      |> Enum.into(%{
        raft_id: raft.id,
        title: "Test Link #{System.unique_integer([:positive])}",
        url: "https://example.com/#{System.unique_integer([:positive])}",
        position: 0,
        is_public: true
      })
    )
    |> Repo.insert!()
  end

  def registration_form_fixture(attrs \\ %{}) do
    user = Map.get_lazy(attrs, :user, fn -> user_fixture() end)
    edition = Map.get_lazy(attrs, :edition, fn -> edition_fixture() end)

    %RegistrationForm{}
    |> RegistrationForm.changeset(
      attrs
      |> Map.drop([:user, :edition])
      |> Enum.into(%{
        user_id: user.id,
        edition_id: edition.id,
        form_type: "participant",
        file_key: "registrations/test_#{System.unique_integer([:positive])}.pdf",
        file_name: "registration.pdf",
        file_size: 1024,
        content_type: "application/pdf"
      })
    )
    |> Repo.insert!()
  end

  def crew_departure_fixture(attrs \\ %{}) do
    user = Map.get_lazy(attrs, :user, fn -> user_fixture() end)
    crew = Map.get_lazy(attrs, :crew, fn -> crew_fixture() end)

    %CrewDeparture{}
    |> CrewDeparture.changeset(
      attrs
      |> Map.drop([:user, :crew])
      |> Enum.into(%{
        user_id: user.id,
        crew_id: crew.id,
        cuf_status_at_departure: "none",
        was_captain: false,
        was_manager: false
      })
    )
    |> Repo.insert!()
  end
end
