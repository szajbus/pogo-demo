import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :pogo_demo, PogoDemoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "+LjIobXcEihyneHQEOcfhcUyI1iL7jHMPJqqa56xFBODizvvUz5uJBLf2/1W/gAl",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
