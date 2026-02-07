defmodule HoMonRadeau.Events do
  @moduledoc """
  The Events context.
  Manages editions, rafts, crews, and related entities.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias HoMonRadeau.Repo
  alias HoMonRadeau.Events.{Edition, Raft, Crew, CrewMember, RaftLink, RegistrationForm}
  alias HoMonRadeau.Storage
  alias HoMonRadeau.Accounts.User

  ## Editions

  @doc """
  Returns the list of all editions.
  """
  def list_editions do
    Edition
    |> order_by([e], desc: e.year)
    |> Repo.all()
  end

  @doc """
  Gets a single edition.
  Raises `Ecto.NoResultsError` if the Edition does not exist.
  """
  def get_edition!(id), do: Repo.get!(Edition, id)

  @doc """
  Gets an edition by year.
  Returns nil if not found.
  """
  def get_edition_by_year(year) when is_integer(year) do
    Repo.get_by(Edition, year: year)
  end

  @doc """
  Gets the current edition (is_current = true).
  Returns nil if no current edition is set.
  """
  def get_current_edition do
    Repo.get_by(Edition, is_current: true)
  end

  @doc """
  Gets or creates the current edition for the given year.
  If no edition exists for the year, creates one.
  If an edition exists but is not current, makes it current.
  """
  def get_or_create_current_edition(year \\ nil) do
    year = year || Date.utc_today().year

    case get_edition_by_year(year) do
      nil ->
        create_edition(%{year: year, name: "Tutto Blu #{year}", is_current: true})

      edition ->
        if edition.is_current do
          {:ok, edition}
        else
          set_current_edition(edition)
        end
    end
  end

  @doc """
  Creates an edition.
  """
  def create_edition(attrs \\ %{}) do
    %Edition{}
    |> Edition.changeset(attrs)
    |> maybe_unset_other_current(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an edition.
  """
  def update_edition(%Edition{} = edition, attrs) do
    edition
    |> Edition.changeset(attrs)
    |> maybe_unset_other_current(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an edition.
  """
  def delete_edition(%Edition{} = edition) do
    Repo.delete(edition)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking edition changes.
  """
  def change_edition(%Edition{} = edition, attrs \\ %{}) do
    Edition.changeset(edition, attrs)
  end

  @doc """
  Sets an edition as the current one, unsetting any other current edition.
  """
  def set_current_edition(%Edition{} = edition) do
    Repo.transaction(fn ->
      # Unset all other current editions
      from(e in Edition, where: e.is_current == true and e.id != ^edition.id)
      |> Repo.update_all(set: [is_current: false])

      # Set this edition as current
      edition
      |> Edition.changeset(%{is_current: true})
      |> Repo.update!()
    end)
  end

  # If setting is_current to true, unset all other current editions
  defp maybe_unset_other_current(changeset, attrs) do
    if Map.get(attrs, :is_current) == true || Map.get(attrs, "is_current") == true do
      Ecto.Changeset.prepare_changes(changeset, fn changeset ->
        from(e in Edition, where: e.is_current == true)
        |> changeset.repo.update_all(set: [is_current: false])

        changeset
      end)
    else
      changeset
    end
  end

  ## Rafts

  @doc """
  Lists all rafts for an edition.
  Returns rafts ordered by validated status (participants first) then by name.
  """
  def list_rafts(edition_id) do
    Raft
    |> where([r], r.edition_id == ^edition_id)
    |> order_by([r], desc: r.validated, asc: r.name)
    |> preload([:crew])
    |> Repo.all()
  end

  @doc """
  Lists all rafts for the current edition.
  """
  def list_current_edition_rafts do
    case get_current_edition() do
      nil -> []
      edition -> list_rafts(edition.id)
    end
  end

  @doc """
  Gets a single raft.
  Raises `Ecto.NoResultsError` if the Raft does not exist.
  """
  def get_raft!(id), do: Repo.get!(Raft, id) |> Repo.preload([:crew, :edition, :links])

  @doc """
  Gets a raft by slug for an edition.
  """
  def get_raft_by_slug(slug, edition_id) do
    Raft
    |> where([r], r.slug == ^slug and r.edition_id == ^edition_id)
    |> preload([:crew, :edition, :links])
    |> Repo.one()
  end

  @doc """
  Creates a raft with its associated crew and the creator as first manager.
  This is a transactional operation.
  """
  def create_raft_with_crew(%User{} = user, attrs) do
    edition = get_current_edition()

    if is_nil(edition) do
      {:error, :no_current_edition}
    else
      create_raft_with_crew(user, attrs, edition.id)
    end
  end

  def create_raft_with_crew(%User{} = user, attrs, edition_id) do
    Multi.new()
    |> Multi.insert(:raft, fn _ ->
      %Raft{}
      |> Raft.changeset(Map.put(attrs, :edition_id, edition_id))
    end)
    |> Multi.insert(:crew, fn %{raft: raft} ->
      %Crew{}
      |> Crew.changeset(%{raft_id: raft.id, edition_id: edition_id})
    end)
    |> Multi.insert(:creator_member, fn %{crew: crew} ->
      %CrewMember{}
      |> CrewMember.changeset(%{
        crew_id: crew.id,
        user_id: user.id,
        is_manager: true
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{raft: raft, crew: crew, creator_member: _member}} ->
        {:ok, %{raft | crew: crew}}

      {:error, :raft, changeset, _} ->
        {:error, changeset}

      {:error, _, _, _} = error ->
        error
    end
  end

  @doc """
  Updates a raft.
  """
  def update_raft(%Raft{} = raft, attrs) do
    raft
    |> Raft.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns a changeset for editing a raft.
  """
  def change_raft(%Raft{} = raft, attrs \\ %{}) do
    Raft.changeset(raft, attrs)
  end

  @doc """
  Validates a raft (admin action).
  """
  def validate_raft(%Raft{} = raft, %User{} = admin) do
    raft
    |> Raft.validation_changeset(%{
      validated: true,
      validated_at: DateTime.utc_now(:second),
      validated_by_id: admin.id
    })
    |> Repo.update()
  end

  @doc """
  Invalidates a raft (admin action).
  """
  def invalidate_raft(%Raft{} = raft) do
    raft
    |> Raft.validation_changeset(%{
      validated: false,
      validated_at: nil,
      validated_by_id: nil
    })
    |> Repo.update()
  end

  ## Crews

  @doc """
  Gets a crew by raft ID.
  """
  def get_crew_by_raft(raft_id) do
    Crew
    |> where([c], c.raft_id == ^raft_id)
    |> preload(crew_members: :user)
    |> Repo.one()
  end

  @doc """
  Gets the crew for a user in the current edition.
  Returns nil if user is not in any crew.
  """
  def get_user_crew(%User{} = user) do
    case get_current_edition() do
      nil ->
        nil

      edition ->
        from(cm in CrewMember,
          join: c in Crew,
          on: c.id == cm.crew_id,
          where: cm.user_id == ^user.id and c.edition_id == ^edition.id,
          preload: [crew: [:raft]]
        )
        |> Repo.one()
        |> case do
          nil -> nil
          member -> member.crew
        end
    end
  end

  @doc """
  Checks if a user is a member of any crew in the current edition.
  """
  def user_has_crew?(%User{} = user) do
    get_user_crew(user) != nil
  end

  ## Crew Members

  @doc """
  Lists all members of a crew.
  """
  def list_crew_members(crew_id) do
    CrewMember
    |> where([cm], cm.crew_id == ^crew_id)
    |> preload(:user)
    |> order_by([cm], desc: cm.is_manager, desc: cm.is_captain, asc: cm.joined_at)
    |> Repo.all()
  end

  @doc """
  Gets public crew members (those with a nickname).
  """
  def get_public_crew_members(crew_id) do
    from(cm in CrewMember,
      where: cm.crew_id == ^crew_id,
      join: u in User,
      on: u.id == cm.user_id,
      where: not is_nil(u.nickname),
      select: %{
        id: cm.id,
        nickname: u.nickname,
        profile_picture_url: u.profile_picture_url,
        profile_picture_public: u.profile_picture_public
      },
      order_by: u.nickname
    )
    |> Repo.all()
  end

  @doc """
  Counts secret members (those without nickname or with private photo).
  """
  def count_secret_members(crew_id) do
    from(cm in CrewMember,
      where: cm.crew_id == ^crew_id,
      join: u in User,
      on: u.id == cm.user_id,
      where: is_nil(u.nickname) or u.profile_picture_public == false
    )
    |> Repo.aggregate(:count)
  end

  @doc """
  Counts total crew members.
  """
  def count_crew_members(crew_id) do
    CrewMember
    |> where([cm], cm.crew_id == ^crew_id)
    |> Repo.aggregate(:count)
  end

  @doc """
  Adds a member to a crew.
  """
  def add_crew_member(crew_id, user_id, attrs \\ %{}) do
    %CrewMember{}
    |> CrewMember.changeset(Map.merge(attrs, %{crew_id: crew_id, user_id: user_id}))
    |> Repo.insert()
  end

  @doc """
  Removes a member from a crew.
  """
  def remove_crew_member(crew_id, user_id) do
    CrewMember
    |> where([cm], cm.crew_id == ^crew_id and cm.user_id == ^user_id)
    |> Repo.delete_all()
  end

  @doc """
  Gets a crew member.
  """
  def get_crew_member(crew_id, user_id) do
    CrewMember
    |> where([cm], cm.crew_id == ^crew_id and cm.user_id == ^user_id)
    |> preload(:user)
    |> Repo.one()
  end

  @doc """
  Promotes a crew member to manager.
  """
  def promote_to_manager(crew_id, user_id) do
    case get_crew_member(crew_id, user_id) do
      nil ->
        {:error, :not_found}

      member ->
        member
        |> CrewMember.promote_to_manager_changeset()
        |> Repo.update()
    end
  end

  @doc """
  Demotes a crew member from manager.
  """
  def demote_from_manager(crew_id, user_id) do
    case get_crew_member(crew_id, user_id) do
      nil ->
        {:error, :not_found}

      member ->
        member
        |> CrewMember.demote_from_manager_changeset()
        |> Repo.update()
    end
  end

  @doc """
  Sets the captain of a crew.
  Only one captain per crew - this unsets any existing captain.
  """
  def set_captain(crew_id, user_id) do
    Repo.transaction(fn ->
      # Unset existing captain
      from(cm in CrewMember, where: cm.crew_id == ^crew_id and cm.is_captain == true)
      |> Repo.update_all(set: [is_captain: false])

      # Set new captain
      case get_crew_member(crew_id, user_id) do
        nil ->
          Repo.rollback(:not_found)

        member ->
          member
          |> CrewMember.set_captain_changeset(true)
          |> Repo.update!()
      end
    end)
  end

  @doc """
  Checks if a user is a manager of a crew.
  """
  def is_manager?(crew_id, user_id) do
    CrewMember
    |> where([cm], cm.crew_id == ^crew_id and cm.user_id == ^user_id and cm.is_manager == true)
    |> Repo.exists?()
  end

  @doc """
  Gets all managers of a crew.
  """
  def get_crew_managers(crew_id) do
    CrewMember
    |> where([cm], cm.crew_id == ^crew_id and cm.is_manager == true)
    |> preload(:user)
    |> Repo.all()
  end

  ## Raft Links

  @doc """
  Lists all public links for a raft.
  """
  def list_raft_links(raft_id) do
    RaftLink
    |> where([rl], rl.raft_id == ^raft_id)
    |> order_by([rl], asc: rl.position)
    |> Repo.all()
  end

  @doc """
  Creates a raft link.
  """
  def create_raft_link(attrs) do
    %RaftLink{}
    |> RaftLink.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a raft link.
  """
  def update_raft_link(%RaftLink{} = link, attrs) do
    link
    |> RaftLink.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a raft link.
  """
  def delete_raft_link(%RaftLink{} = link) do
    Repo.delete(link)
  end

  ## Registration Forms

  @doc """
  Gets the current (most recent) registration form for a user in an edition.
  Returns nil if no form has been uploaded.
  """
  def get_current_registration_form(user_id, edition_id) do
    from(rf in RegistrationForm,
      where: rf.user_id == ^user_id and rf.edition_id == ^edition_id,
      order_by: [desc: rf.uploaded_at],
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  Gets all registration forms for a user in an edition (history).
  """
  def list_user_registration_forms(user_id, edition_id) do
    from(rf in RegistrationForm,
      where: rf.user_id == ^user_id and rf.edition_id == ^edition_id,
      order_by: [desc: rf.uploaded_at],
      preload: [:reviewed_by]
    )
    |> Repo.all()
  end

  @doc """
  Gets a registration form by ID.
  """
  def get_registration_form!(id) do
    RegistrationForm
    |> Repo.get!(id)
    |> Repo.preload([:user, :edition, :reviewed_by])
  end

  @doc """
  Determines the required form type for a user based on their crew role.
  Returns :captain, :participant, or nil if user is not in a crew.
  """
  def required_form_type(%User{} = user, edition_id) do
    from(cm in CrewMember,
      join: c in Crew,
      on: c.id == cm.crew_id,
      where: cm.user_id == ^user.id and c.edition_id == ^edition_id,
      select: cm.is_captain
    )
    |> Repo.one()
    |> case do
      nil -> nil
      true -> :captain
      false -> :participant
    end
  end

  @doc """
  Returns the registration form status for a user.
  Possible values: :missing, :pending, :approved, :rejected
  """
  def registration_form_status(%User{} = user, edition_id) do
    case get_current_registration_form(user.id, edition_id) do
      nil -> :missing
      %{status: "approved"} -> :approved
      %{status: "rejected"} -> :rejected
      %{status: "pending"} -> :pending
    end
  end

  @doc """
  Uploads a registration form for a user.
  Stores the file and creates a database record.
  """
  def upload_registration_form(%User{} = user, edition_id, file_params) do
    form_type = required_form_type(user, edition_id)

    if is_nil(form_type) do
      {:error, :not_in_crew}
    else
      do_upload_registration_form(user, edition_id, form_type, file_params)
    end
  end

  defp do_upload_registration_form(user, edition_id, form_type, %{
         filename: filename,
         content: content,
         content_type: content_type
       }) do
    file_key = Storage.registration_form_key(edition_id, user.id, filename)

    with {:ok, _key} <- Storage.upload(file_key, content, content_type: content_type) do
      %RegistrationForm{}
      |> RegistrationForm.changeset(%{
        user_id: user.id,
        edition_id: edition_id,
        form_type: Atom.to_string(form_type),
        file_key: file_key,
        file_name: filename,
        file_size: byte_size(content),
        content_type: content_type
      })
      |> Repo.insert()
    end
  end

  @doc """
  Approves a registration form.
  """
  def approve_registration_form(%RegistrationForm{} = form, %User{} = reviewer) do
    form
    |> RegistrationForm.approve_changeset(reviewer.id)
    |> Repo.update()
  end

  @doc """
  Rejects a registration form with a reason.
  """
  def reject_registration_form(%RegistrationForm{} = form, %User{} = reviewer, reason) do
    form
    |> RegistrationForm.reject_changeset(reviewer.id, reason)
    |> Repo.update()
  end

  @doc """
  Deletes a registration form and its associated file.
  Admin only action.
  """
  def delete_registration_form(%RegistrationForm{} = form) do
    with :ok <- Storage.delete(form.file_key) do
      Repo.delete(form)
    end
  end

  @doc """
  Gets the download URL for a registration form.
  """
  def get_registration_form_url(%RegistrationForm{} = form, opts \\ []) do
    Storage.get_url(form.file_key, opts)
  end

  @doc """
  Lists all pending registration forms for an edition.
  """
  def list_pending_registration_forms(edition_id) do
    from(rf in RegistrationForm,
      where: rf.edition_id == ^edition_id and rf.status == "pending",
      order_by: [asc: rf.uploaded_at],
      preload: [:user]
    )
    |> Repo.all()
  end

  @doc """
  Lists all registration forms for an edition with optional filters.
  """
  def list_registration_forms(edition_id, opts \\ []) do
    status = Keyword.get(opts, :status)
    raft_id = Keyword.get(opts, :raft_id)

    query =
      from(rf in RegistrationForm,
        where: rf.edition_id == ^edition_id,
        order_by: [desc: rf.uploaded_at],
        preload: [:user, :reviewed_by]
      )

    query =
      if status do
        where(query, [rf], rf.status == ^status)
      else
        query
      end

    query =
      if raft_id do
        from(rf in query,
          join: cm in CrewMember,
          on: cm.user_id == rf.user_id,
          join: c in Crew,
          on: c.id == cm.crew_id,
          where: c.raft_id == ^raft_id
        )
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Gets registration form statistics for an edition grouped by raft.
  Returns a list of maps with raft info and form counts.
  """
  def registration_form_stats_by_raft(edition_id) do
    # Get all rafts with their crew members
    rafts_with_members =
      from(r in Raft,
        join: c in Crew,
        on: c.raft_id == r.id,
        join: cm in CrewMember,
        on: cm.crew_id == c.id,
        where: r.edition_id == ^edition_id,
        select: %{raft_id: r.id, raft_name: r.name, user_id: cm.user_id}
      )
      |> Repo.all()

    # Group by raft and compute stats
    rafts_with_members
    |> Enum.group_by(fn %{raft_id: id, raft_name: name} -> {id, name} end)
    |> Enum.map(fn {{raft_id, raft_name}, members} ->
      user_ids = Enum.map(members, & &1.user_id)

      # Get current form status for each user
      form_statuses =
        Enum.map(user_ids, fn user_id ->
          registration_form_status(%User{id: user_id}, edition_id)
        end)

      %{
        raft_id: raft_id,
        raft_name: raft_name,
        total_members: length(members),
        approved: Enum.count(form_statuses, &(&1 == :approved)),
        pending: Enum.count(form_statuses, &(&1 == :pending)),
        rejected: Enum.count(form_statuses, &(&1 == :rejected)),
        missing: Enum.count(form_statuses, &(&1 == :missing))
      }
    end)
  end

  @doc """
  Gets crew members who are missing or have rejected registration forms for a raft.
  """
  def get_crew_members_missing_forms(raft_id, edition_id) do
    # Get all crew members for this raft
    crew_members =
      from(cm in CrewMember,
        join: c in Crew,
        on: c.id == cm.crew_id,
        join: u in User,
        on: u.id == cm.user_id,
        where: c.raft_id == ^raft_id and c.edition_id == ^edition_id,
        select: %{user: u, is_captain: cm.is_captain}
      )
      |> Repo.all()

    # Filter to those with missing or rejected forms
    Enum.filter(crew_members, fn %{user: user} ->
      status = registration_form_status(user, edition_id)
      status in [:missing, :rejected]
    end)
    |> Enum.map(fn member ->
      status = registration_form_status(member.user, edition_id)
      Map.put(member, :form_status, Atom.to_string(status))
    end)
  end
end
