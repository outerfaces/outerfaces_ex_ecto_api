defmodule OuterfacesEctoApi.MixProject do
  use Mix.Project

  def project do
    [
      app: :outerfaces_ex_ecto_api,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sql, "~> 3.12"},
      {:jason, "~> 1.2"}
    ]
  end
end
