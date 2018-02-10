use Mix.Config

data_dir = Path.join [__DIR__, "..", "timezonedata"]

config :tzdata, :data_dir, data_dir
