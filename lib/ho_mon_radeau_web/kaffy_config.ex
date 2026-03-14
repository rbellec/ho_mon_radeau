defmodule HoMonRadeauWeb.KaffyConfig do
  @moduledoc """
  Configuration for Kaffy admin interface.
  """

  def create_resources(_conn) do
    [
      accounts: [
        name: "Comptes",
        resources: [
          user: [
            schema: HoMonRadeau.Accounts.User,
            admin: HoMonRadeauWeb.Admin.UserKaffy
          ]
        ]
      ],
      events: [
        name: "Événements",
        resources: [
          edition: [schema: HoMonRadeau.Events.Edition],
          raft: [schema: HoMonRadeau.Events.Raft],
          crew: [schema: HoMonRadeau.Events.Crew],
          crew_member: [schema: HoMonRadeau.Events.CrewMember],
          crew_join_request: [schema: HoMonRadeau.Events.CrewJoinRequest]
        ]
      ],
      registration: [
        name: "Inscriptions",
        resources: [
          registration_form: [schema: HoMonRadeau.Events.RegistrationForm]
        ]
      ]
    ]
  end
end
