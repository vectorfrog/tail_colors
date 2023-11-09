defmodule TailColors.Mixfile do
  use Mix.Project

  @name :tail_colors
  @version "0.2.0"

  @deps [
    {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
  ]

  # ------------------------------------------------------------

  def project do
    in_production = Mix.env() == :prod

    [
      app: @name,
      version: @version,
      elixir: ">= 1.14.2",
      deps: @deps,
      build_embedded: in_production,
      description:
        "Helper functions for working with tailwind css color classes when building out Phoenix.Components/LiveComponents in a DaisyUI opinionated way",
      package: package(),
      name: "TailColors",
      source_url: "https://github.com/vectorfrog/tail_colors",
      docs: [
        main: "TailColors",
        extras: ["README.md"]
      ]
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
