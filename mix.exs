defmodule OuterfacesEctoApi.MixProject do
  use Mix.Project

  @github_url "https://github.com/outerfaces/outerfaces_ex_ecto_api"

  def project do
    [
      app: :outerfaces_ex_ecto_api,
      version: "0.2.7",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Outerfaces Ecto API",
      description: "'Good Enough' Query Engine for Ecto",
      source_url: @github_url,
      package: package()
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
      {:jason, "~> 1.2"},
      {:ex_doc, "~> 0.37", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Aligned To Development - development@alignedto.dev"],
      licenses: ["MIT"],
      links: %{"GitHub" => @github_url}
    ]
  end
end
