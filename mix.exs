defmodule TailColors.Mixfile do
  use Mix.Project

  @name :tail_colors
  @version "0.1.1"

  @deps []

  # ------------------------------------------------------------

  def project do
    in_production = Mix.env() == :prod

    [
      app: @name,
      version: @version,
      elixir: ">= 1.14.2",
      deps: @deps,
      build_embedded: in_production,
      descrption:
        "Helper functions for working with tailwind css color classes when building out Phoenix.Components/LiveComponents",
      package: package(),
      name: "TailColors",
      source_url: "https://github.com/vectorfrog/tail_colors"
    ]
  end

  def application do
    [
      # built-in apps that need starting    
      extra_applications: [
        :logger
      ]
    ]
  end

  def package() do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/vectorfrog/tail_colors"}
    ]
  end
end
