import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :weather, WeatherWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "2S8hudgcgyXJDC6mk6Zf7frr0oCxluMuI0FxQw+tAQanS1dDiZxvDJ8wzJ9BCq/a",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
