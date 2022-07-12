import Config

# TODO is it loaded when salaryman is a dep?
if config_env() == :dev do
  config :salaryman, Sm.Repo, database: "salaryman_dev.db", pool_size: 5, cache_size: -2000
end
