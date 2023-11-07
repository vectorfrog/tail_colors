import Config

#     config(:tail_colors, key: :value)
#
# And access this configuration in your application as:
#
#     Application.get_env(:tail_colors, :key)
#
# Or configure a 3rd-party app:
#
#     config(:logger, level: :info)
#

# Example per-environment config:
#
#     import_config("#{Mix.env}.exs")
#
config :tail_colors,
  colors: [
    "hawthorne",
    "burgandy",
    "silver-hawk"
  ],
  themed_colors: %{
    primary: "purple",
    secondary: "blue",
    accent: "yellow",
    info: "sky",
    success: "green",
    warning: "orange",
    error: "red",
    base: "slate"
  }
