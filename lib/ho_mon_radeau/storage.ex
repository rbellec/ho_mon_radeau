defmodule HoMonRadeau.Storage do
  @moduledoc """
  Storage module for handling file uploads.
  Supports local file storage (development) and S3/Tigris (production).
  """

  @doc """
  Uploads a file to storage.

  ## Parameters
    - `path`: The storage path/key for the file
    - `content`: The binary content of the file
    - `opts`: Options including :content_type

  ## Returns
    - `{:ok, key}` on success
    - `{:error, reason}` on failure
  """
  def upload(path, content, opts \\ []) do
    config = get_config()

    if config[:enabled] do
      case config[:adapter] do
        :local -> upload_local(path, content, config)
        _ -> upload_s3(path, content, opts, config)
      end
    else
      {:error, :storage_disabled}
    end
  end

  @doc """
  Downloads a file from storage.

  ## Parameters
    - `path`: The storage path/key for the file

  ## Returns
    - `{:ok, binary}` on success
    - `{:error, reason}` on failure
  """
  def download(path) do
    config = get_config()

    if config[:enabled] do
      case config[:adapter] do
        :local -> download_local(path, config)
        _ -> download_s3(path, config)
      end
    else
      {:error, :storage_disabled}
    end
  end

  @doc """
  Deletes a file from storage.

  ## Parameters
    - `path`: The storage path/key for the file

  ## Returns
    - `:ok` on success
    - `{:error, reason}` on failure
  """
  def delete(path) do
    config = get_config()

    if config[:enabled] do
      case config[:adapter] do
        :local -> delete_local(path, config)
        _ -> delete_s3(path, config)
      end
    else
      {:error, :storage_disabled}
    end
  end

  @doc """
  Generates a URL for accessing a file.
  For local storage, returns a static path.
  For S3, generates a presigned URL with expiration.

  ## Parameters
    - `path`: The storage path/key for the file
    - `opts`: Options including :expires_in (seconds, default 3600)

  ## Returns
    - `{:ok, url}` on success
    - `{:error, reason}` on failure
  """
  def get_url(path, opts \\ []) do
    config = get_config()

    if config[:enabled] do
      case config[:adapter] do
        :local -> get_url_local(path, config)
        _ -> get_url_s3(path, opts, config)
      end
    else
      {:error, :storage_disabled}
    end
  end

  @doc """
  Checks if storage is enabled.
  """
  def enabled? do
    get_config()[:enabled] == true
  end

  @doc """
  Generates a storage key for a registration form.
  """
  def registration_form_key(edition_id, user_id, filename) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    safe_filename = sanitize_filename(filename)
    "registration_forms/#{edition_id}/#{user_id}/#{timestamp}_#{safe_filename}"
  end

  # Private functions

  defp get_config do
    Application.get_env(:ho_mon_radeau, :storage, [])
  end

  defp sanitize_filename(filename) do
    filename
    |> String.replace(~r/[^a-zA-Z0-9._-]/, "_")
    |> String.slice(0, 100)
  end

  # Local storage implementation

  defp upload_local(path, content, config) do
    upload_dir = config[:upload_dir] || "priv/static/uploads"
    full_path = Path.join(upload_dir, path)

    with :ok <- full_path |> Path.dirname() |> File.mkdir_p(),
         :ok <- File.write(full_path, content) do
      {:ok, path}
    end
  end

  defp download_local(path, config) do
    upload_dir = config[:upload_dir] || "priv/static/uploads"
    full_path = Path.join(upload_dir, path)
    File.read(full_path)
  end

  defp delete_local(path, config) do
    upload_dir = config[:upload_dir] || "priv/static/uploads"
    full_path = Path.join(upload_dir, path)

    case File.rm(full_path) do
      :ok -> :ok
      {:error, :enoent} -> :ok
      error -> error
    end
  end

  defp get_url_local(path, config) do
    upload_dir = config[:upload_dir] || "priv/static/uploads"

    if String.starts_with?(upload_dir, "priv/static") do
      # Serve from static path
      relative_path = String.replace_prefix(upload_dir, "priv/static", "")
      {:ok, Path.join([relative_path, path])}
    else
      # For test uploads or other paths, return the file path
      {:ok, Path.join(upload_dir, path)}
    end
  end

  # S3/Tigris implementation

  defp upload_s3(path, content, opts, config) do
    bucket = config[:bucket]
    content_type = opts[:content_type] || "application/octet-stream"

    case ExAws.S3.put_object(bucket, path, content, content_type: content_type)
         |> ExAws.request() do
      {:ok, _} -> {:ok, path}
      {:error, reason} -> {:error, reason}
    end
  end

  defp download_s3(path, config) do
    bucket = config[:bucket]

    case ExAws.S3.get_object(bucket, path) |> ExAws.request() do
      {:ok, %{body: body}} -> {:ok, body}
      {:error, reason} -> {:error, reason}
    end
  end

  defp delete_s3(path, config) do
    bucket = config[:bucket]

    case ExAws.S3.delete_object(bucket, path) |> ExAws.request() do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_url_s3(path, opts, config) do
    bucket = config[:bucket]
    expires_in = opts[:expires_in] || 3600

    {:ok, url} =
      ExAws.S3.presigned_url(ExAws.Config.new(:s3), :get, bucket, path,
        expires_in: expires_in
      )

    {:ok, url}
  end
end
