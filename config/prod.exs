use Mix.Config

# For production, we configure the host to read the PORT
# from the system environment. Therefore, you will need
# to set PORT=80 before running your server.
#
# You should also configure the url host to something
# meaningful, we use this information when generating URLs.
#
# Finally, we also include the path to a manifest
# containing the digested version of static files. This
# manifest is generated by the mix phoenix.digest task
# which you typically run after static files are built.
config :poker_ex, PokerExWeb.Endpoint,
  load_from_system_env: true,
  http: [port: {:system, "PORT"}],
  url: [scheme: "https", host: "https://pokerex.herokuapp.com", port: 443],
  force_ssl: [rewrite_on: [:x_forwarded_proto]],
  cache_static_manifest: "priv/static/cache_manifest.json",
  secret_key_base: System.get_env("SECRET_KEY_BASE")

# Do not print debug messages in production
config :logger, level: :info

config :poker_ex, PokerEx.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  ssl: true

# TODO: Define these environment variables on Heroku.
# Also, you will have to verify your domain with
# Mailgun before you can actuallY start sending emails in prod.
config :poker_ex, PokerEx.Mailer,
	adapter: Bamboo.MailgunAdapter,
	api_key: System.get_env("MAILGUN_API_KEY"),
	domain: System.get_env("MAILGUN_DOMAIN")

# The client's endpoint is unknown at this point
# This MUST be changed before the client is deployed.
config :poker_ex,
  client_password_reset_endpoint: "https://poker-ex.herokuapp.com/#/password-reset"

Application.put_env(PokerEx, :should_update_after_poker_action, true)

# ## SSL Support
#
# To get SSL working, you will need to add the `https` key
# to the previous section and set your `:url` port to 443:
#
#    config :poker_ex, PokerExWeb.Endpoint,
#       ...
#      url: [scheme: "https", host: "https://ancient-forest-15148.herokuapp.com/", port: 443],
#      force_ssl: [rewrite_on: [:x_forwarded_proto]],
#       https: [port: 443,
#               keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
#               certfile: System.get_env("SOME_APP_SSL_CERT_PATH")]
#
# Where those two env variables return an absolute path to
# the key and cert in disk or a relative path inside priv,
# for example "priv/ssl/server.key".
#
# We also recommend setting `force_ssl`, ensuring no data is
# ever sent via http, always redirecting to https:
#
#     config :poker_ex, PokerExWeb.Endpoint,
#       force_ssl: [hsts: true]
#
# Check `Plug.SSL` for all available options in `force_ssl`.

# ## Using releases
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start the server for all endpoints:
#
#     config :phoenix, :serve_endpoints, true
#
# Alternatively, you can configure exactly which server to
# start per endpoint:
#
#     config :poker_ex, PokerExWeb.Endpoint, server: true
#

# Finally import the config/prod.secret.exs
# which should be versioned separately.
# import_config "prod.secret.exs"  ----> Not needed when using environment variables on Heroku
