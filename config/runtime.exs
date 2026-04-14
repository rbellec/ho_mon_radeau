import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/ho_mon_radeau start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :ho_mon_radeau, HoMonRadeauWeb.Endpoint, server: true
end

config :ho_mon_radeau, HoMonRadeauWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", "4000"))]

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :ho_mon_radeau, HoMonRadeau.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    # For machines with several cores, consider starting multiple pools of `pool_size`
    # pool_count: 4,
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"

  config :ho_mon_radeau, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :ho_mon_radeau, HoMonRadeauWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: String.to_integer(System.get_env("PORT") || "4000")
    ],
    secret_key_base: secret_key_base

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :ho_mon_radeau, HoMonRadeauWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :ho_mon_radeau, HoMonRadeauWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # Configuring the mailer with Resend
  config :ho_mon_radeau, HoMonRadeau.Mailer,
    adapter: Swoosh.Adapters.Resend,
    api_key:
      System.get_env("RESEND_API_KEY") ||
        raise("environment variable RESEND_API_KEY is missing.")

  config :ho_mon_radeau,
    mailer_from_email: System.get_env("MAILER_FROM_EMAIL", "onboarding@resend.dev")

  # ## Configuring storage
  #
  # If BUCKET_NAME is set, use S3/Tigris. Otherwise, use local file storage.
  # Local storage writes to UPLOAD_DIR (default: /app/uploads), which should
  # be a Docker volume to persist across deploys.
  if System.get_env("BUCKET_NAME") do
    config :ex_aws,
      access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
      secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
      region: System.get_env("AWS_REGION", "auto")

    config :ex_aws, :s3,
      scheme: "https://",
      host: System.get_env("AWS_ENDPOINT_URL_S3") |> URI.parse() |> Map.get(:host),
      region: System.get_env("AWS_REGION", "auto")

    config :ho_mon_radeau, :storage,
      bucket: System.get_env("BUCKET_NAME"),
      enabled: true
  else
    config :ho_mon_radeau, :storage,
      adapter: :local,
      upload_dir: System.get_env("UPLOAD_DIR", "/app/uploads"),
      enabled: true
  end
end
