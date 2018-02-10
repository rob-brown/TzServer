defmodule TzServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :tz_server,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {TzServer.Application, []}
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.5.0-rc.1"},
      {:tzdata, "~> 0.5.16"},
      {:cowboy, "~> 1.1.2"},
      {:poison, "~> 3.1.0"},
      {:distillery, "~> 1.5", runtime: false}
    ]
  end
end
