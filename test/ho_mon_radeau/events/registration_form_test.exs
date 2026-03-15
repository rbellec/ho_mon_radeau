defmodule HoMonRadeau.Events.RegistrationFormTest do
  use HoMonRadeau.DataCase, async: true

  alias HoMonRadeau.Events.RegistrationForm

  @valid_attrs %{
    user_id: 1,
    edition_id: 1,
    form_type: "participant",
    file_key: "uploads/abc123.pdf",
    file_name: "my_form.pdf"
  }

  describe "changeset/2" do
    test "valid with required fields" do
      changeset = RegistrationForm.changeset(%RegistrationForm{}, @valid_attrs)
      assert changeset.valid?
    end

    test "requires user_id" do
      attrs = Map.drop(@valid_attrs, [:user_id])
      changeset = RegistrationForm.changeset(%RegistrationForm{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).user_id
    end

    test "requires edition_id" do
      attrs = Map.drop(@valid_attrs, [:edition_id])
      changeset = RegistrationForm.changeset(%RegistrationForm{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).edition_id
    end

    test "requires form_type" do
      attrs = Map.drop(@valid_attrs, [:form_type])
      changeset = RegistrationForm.changeset(%RegistrationForm{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).form_type
    end

    test "requires file_key" do
      attrs = Map.drop(@valid_attrs, [:file_key])
      changeset = RegistrationForm.changeset(%RegistrationForm{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).file_key
    end

    test "requires file_name" do
      attrs = Map.drop(@valid_attrs, [:file_name])
      changeset = RegistrationForm.changeset(%RegistrationForm{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).file_name
    end

    test "validates form_type must be participant or captain" do
      attrs = Map.put(@valid_attrs, :form_type, "spectator")
      changeset = RegistrationForm.changeset(%RegistrationForm{}, attrs)
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).form_type
    end

    test "accepts participant form_type" do
      attrs = Map.put(@valid_attrs, :form_type, "participant")
      changeset = RegistrationForm.changeset(%RegistrationForm{}, attrs)
      assert changeset.valid?
    end

    test "accepts captain form_type" do
      attrs = Map.put(@valid_attrs, :form_type, "captain")
      changeset = RegistrationForm.changeset(%RegistrationForm{}, attrs)
      assert changeset.valid?
    end

    test "validates file_size must be at most 10 MB" do
      attrs = Map.put(@valid_attrs, :file_size, 10 * 1024 * 1024 + 1)
      changeset = RegistrationForm.changeset(%RegistrationForm{}, attrs)
      refute changeset.valid?
      assert "must be less than 10 MB" in errors_on(changeset).file_size
    end

    test "accepts file_size exactly 10 MB" do
      attrs = Map.put(@valid_attrs, :file_size, 10 * 1024 * 1024)
      changeset = RegistrationForm.changeset(%RegistrationForm{}, attrs)
      assert changeset.valid?
    end

    test "accepts file_size under 10 MB" do
      attrs = Map.put(@valid_attrs, :file_size, 1024)
      changeset = RegistrationForm.changeset(%RegistrationForm{}, attrs)
      assert changeset.valid?
    end

    test "validates content_type must be PDF or image" do
      attrs = Map.put(@valid_attrs, :content_type, "application/zip")
      changeset = RegistrationForm.changeset(%RegistrationForm{}, attrs)
      refute changeset.valid?
      assert "must be a PDF or image file" in errors_on(changeset).content_type
    end

    test "accepts valid content types" do
      for ct <- ~w(application/pdf image/jpeg image/png image/gif image/webp) do
        attrs = Map.put(@valid_attrs, :content_type, ct)
        changeset = RegistrationForm.changeset(%RegistrationForm{}, attrs)
        assert changeset.valid?, "Expected content_type #{ct} to be valid"
      end
    end

    test "auto-sets uploaded_at when file_key is provided" do
      changeset = RegistrationForm.changeset(%RegistrationForm{}, @valid_attrs)
      assert get_change(changeset, :uploaded_at)
    end

    test "does not override existing uploaded_at" do
      now = DateTime.utc_now(:second)
      existing = %RegistrationForm{uploaded_at: now}
      changeset = RegistrationForm.changeset(existing, @valid_attrs)
      assert get_field(changeset, :uploaded_at) == now
    end
  end

  describe "approve_changeset/2" do
    test "sets status to approved with reviewer info" do
      changeset = RegistrationForm.approve_changeset(%RegistrationForm{}, 42)
      assert get_change(changeset, :status) == "approved"
      assert get_change(changeset, :reviewed_by_id) == 42
      assert get_change(changeset, :reviewed_at)
    end

    test "clears rejection_reason" do
      form = %RegistrationForm{rejection_reason: "bad scan"}
      changeset = RegistrationForm.approve_changeset(form, 42)
      assert get_change(changeset, :rejection_reason) == nil
    end
  end

  describe "reject_changeset/3" do
    test "sets status to rejected with reviewer info and reason" do
      changeset = RegistrationForm.reject_changeset(%RegistrationForm{}, 42, "illegible scan")
      assert get_change(changeset, :status) == "rejected"
      assert get_change(changeset, :reviewed_by_id) == 42
      assert get_change(changeset, :reviewed_at)
      assert get_change(changeset, :rejection_reason) == "illegible scan"
    end

    test "requires rejection_reason" do
      changeset = RegistrationForm.reject_changeset(%RegistrationForm{}, 42, nil)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).rejection_reason
    end
  end

  describe "form_types/0" do
    test "returns expected list" do
      assert RegistrationForm.form_types() == ~w(participant captain)
    end
  end

  describe "statuses/0" do
    test "returns expected list" do
      assert RegistrationForm.statuses() == ~w(pending approved rejected)
    end
  end
end
