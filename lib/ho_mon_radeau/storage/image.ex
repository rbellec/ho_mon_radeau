defmodule HoMonRadeau.Storage.Image do
  @moduledoc """
  Helpers to resize/convert uploaded images before sending them to `HoMonRadeau.Storage`.

  All processed images are converted to JPEG at quality 85.
  """

  alias HoMonRadeau.Storage

  @jpeg_quality 85
  @content_type "image/jpeg"

  @doc """
  Resizes the image at `source_path`, converts it to JPEG and uploads it under `key`.

  ## Options

    * `:width` (required) - target width in pixels
    * `:height` (required) - target height in pixels
    * `:mode` - `:crop` (default, fill exact dimensions, center-cropped) or
      `:fit` (scale down to fit inside the box, preserving aspect ratio)
  """
  def process_and_upload(source_path, key, opts) do
    width = Keyword.fetch!(opts, :width)
    height = Keyword.fetch!(opts, :height)
    mode = Keyword.get(opts, :mode, :crop)

    tmp_path = Path.join(System.tmp_dir!(), "hmr_img_#{System.unique_integer([:positive])}.jpg")

    try do
      with :ok <- process(source_path, tmp_path, width, height, mode),
           {:ok, content} <- File.read(tmp_path),
           {:ok, _} <- Storage.upload(key, content, content_type: @content_type) do
        {:ok, key}
      end
    after
      File.rm(tmp_path)
    end
  end

  defp process(source_path, tmp_path, width, height, mode) do
    geometry = "#{width}x#{height}"

    image =
      source_path
      |> Mogrify.open()
      |> Mogrify.format("jpg")
      |> Mogrify.quality(@jpeg_quality)

    image =
      case mode do
        :crop ->
          image
          |> Mogrify.resize_to_fill(geometry)

        :fit ->
          image
          |> Mogrify.resize_to_limit(geometry)
      end

    image
    |> Mogrify.custom("strip")
    |> Mogrify.save(path: tmp_path)

    :ok
  rescue
    e -> {:error, Exception.message(e)}
  end
end
