defmodule HoMonRadeau.StorageTest do
  use HoMonRadeau.DataCase, async: true

  alias HoMonRadeau.Storage

  @test_content "hello world"

  setup do
    # Create a temporary directory for local storage tests
    tmp_dir = Path.join(System.tmp_dir!(), "storage_test_#{:erlang.unique_integer([:positive])}")
    File.mkdir_p!(tmp_dir)

    # Save original config and set local adapter config
    original_config = Application.get_env(:ho_mon_radeau, :storage, [])

    Application.put_env(:ho_mon_radeau, :storage,
      enabled: true,
      adapter: :local,
      upload_dir: tmp_dir
    )

    on_exit(fn ->
      # Restore original config and clean up temp directory
      Application.put_env(:ho_mon_radeau, :storage, original_config)
      File.rm_rf!(tmp_dir)
    end)

    %{tmp_dir: tmp_dir}
  end

  describe "registration_form_key/3" do
    test "generates a key with edition_id, user_id, and filename" do
      key = Storage.registration_form_key(1, 42, "document.pdf")

      assert key =~ ~r"^registration_forms/1/42/\d+_document\.pdf$"
    end

    test "sanitizes special characters in the filename" do
      key = Storage.registration_form_key(1, 2, "my file (1) @special!.pdf")

      # Special characters should be replaced with underscores
      refute key =~ " "
      refute key =~ "("
      refute key =~ ")"
      refute key =~ "@"
      refute key =~ "!"
      assert key =~ "my_file__1___special_.pdf"
    end

    test "preserves allowed characters in the filename" do
      key = Storage.registration_form_key(1, 2, "valid-file_name.2024.pdf")

      assert key =~ "valid-file_name.2024.pdf"
    end

    test "truncates filename to 100 characters" do
      long_name = String.duplicate("a", 150) <> ".pdf"
      key = Storage.registration_form_key(1, 2, long_name)

      # Extract the filename part (after the timestamp_)
      [_, filename_part] = Regex.run(~r"/\d+_(.+)$", key)
      assert String.length(filename_part) <= 100
    end
  end

  describe "upload/3 (local adapter)" do
    test "creates a file on disk", %{tmp_dir: tmp_dir} do
      path = "test/file.txt"

      assert {:ok, ^path} = Storage.upload(path, @test_content)
      assert File.read!(Path.join(tmp_dir, path)) == @test_content
    end

    test "creates intermediate directories", %{tmp_dir: tmp_dir} do
      path = "deep/nested/dir/file.txt"

      assert {:ok, ^path} = Storage.upload(path, @test_content)
      assert File.exists?(Path.join(tmp_dir, path))
    end

    test "returns error when storage is disabled" do
      Application.put_env(:ho_mon_radeau, :storage, enabled: false)

      assert {:error, :storage_disabled} = Storage.upload("key", "content")
    end
  end

  describe "download/1 (local adapter)" do
    test "reads file content" do
      path = "test/download.txt"
      Storage.upload(path, @test_content)

      assert {:ok, @test_content} = Storage.download(path)
    end

    test "returns error for non-existent file" do
      assert {:error, :enoent} = Storage.download("nonexistent.txt")
    end

    test "returns error when storage is disabled" do
      Application.put_env(:ho_mon_radeau, :storage, enabled: false)

      assert {:error, :storage_disabled} = Storage.download("key")
    end
  end

  describe "delete/1 (local adapter)" do
    test "deletes an existing file", %{tmp_dir: tmp_dir} do
      path = "test/to_delete.txt"
      Storage.upload(path, @test_content)
      assert File.exists?(Path.join(tmp_dir, path))

      assert :ok = Storage.delete(path)
      refute File.exists?(Path.join(tmp_dir, path))
    end

    test "returns :ok for a non-existent file" do
      assert :ok = Storage.delete("does_not_exist.txt")
    end

    test "returns error when storage is disabled" do
      Application.put_env(:ho_mon_radeau, :storage, enabled: false)

      assert {:error, :storage_disabled} = Storage.delete("key")
    end
  end

  describe "get_url/2 (local adapter)" do
    test "returns the file path for non-static upload directories", %{tmp_dir: tmp_dir} do
      path = "test/image.png"

      assert {:ok, url} = Storage.get_url(path)
      assert url == Path.join(tmp_dir, path)
    end

    test "returns a relative static path when upload_dir starts with priv/static" do
      Application.put_env(:ho_mon_radeau, :storage,
        enabled: true,
        adapter: :local,
        upload_dir: "priv/static/uploads"
      )

      path = "test/image.png"

      assert {:ok, url} = Storage.get_url(path)
      assert url == "/uploads/test/image.png"
    end

    test "returns error when storage is disabled" do
      Application.put_env(:ho_mon_radeau, :storage, enabled: false)

      assert {:error, :storage_disabled} = Storage.get_url("key")
    end
  end

  describe "enabled?/0" do
    test "returns true when storage is enabled" do
      Application.put_env(:ho_mon_radeau, :storage, enabled: true, adapter: :local)

      assert Storage.enabled?()
    end

    test "returns false when storage is disabled" do
      Application.put_env(:ho_mon_radeau, :storage, enabled: false)

      refute Storage.enabled?()
    end

    test "returns false when storage config is missing" do
      Application.delete_env(:ho_mon_radeau, :storage)

      refute Storage.enabled?()
    end
  end
end
