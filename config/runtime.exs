import Config

# TODO is it loaded when soju is a dep?
if config_env() == :dev do
  config :soju, Soju.Repo, database: "soju_dev.db", pool_size: 5, cache_size: -2000
end
