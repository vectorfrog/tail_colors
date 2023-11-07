defmodule TailColors.Mixfile do
  use Mix.Project

  @name :tail_colors
  @version "0.1.1"

  @deps [
    # { :earmark, ">0.1.5" },                      
    # { :ex_doc,  "1.2.3", only: [ :dev, :test ] }
    # { :my_app:  path: "../my_app" },
  ]

  # ------------------------------------------------------------

  def project do
    in_production = Mix.env() == :prod

    [
      app: @name,
      version: @version,
      elixir: ">= 1.14.2",
      deps: @deps,
      build_embedded: in_production
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
end
