# TailColors

This library is a collection of useful functions for working with tailwind colors.  It is meant to be a helper library if you're building out your own custom components that utilize class names to key logic off of.  Essentially, I wanted to build my own version of daisyUI, using my own components, but passing style information through the class string, instead of as props.


## Installation

```elixir
@deps [
tail_colors: "~> 0.1.0"
]
```
## Config

First configure tail_color schemes in config.exs

```elixir
import Config

config :tail_colors,
  primary: "purple",
  secondary: "blue",
  accent: "yellow",
  info: "sky",
  success: "green",
  warning: "orange",
  error: "red",
```
If you are using custom colors in your tailwind.config.js file, you can add those colors so they will identified as colors to identify in your class names:

```elixir
import Config

config :tail_colors,
  colors: [
    "hawthorne",
    "midnight"
  ],
```

Additionally, if you'd like to have your own custom schemes to identify, you can by just adding them to the config as well:

```elixir
import Config

config :tail_colors,
  schemes: [
    "ghost",
    "box"
  ],
```

## Usage

**Substitution vs Append**

By default, TailColors will automatically replace the "primary", "secondary", "accent", "info", "success", "warning", and "error" settings with their associated colors.  So "text-primary-500" will be removed and replaced with "text-purple-500".

## License

MIT License

----
Created:  2023-11-06Z
