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

## Usage

TailColors provides a few functions to help you build out your own components where you pass in data through the class attribute.  For example, if you want to build a button component, you can pass in the color, style, and size of the button through the class attribute, and then use TailColors to parse out the data, and modify the classes.

**Your call to your component might look like this:**
```elixir
<.button class="primary box xl">Hello</.button>
```

Notice how we are passing in the "primary" class.  TailColors will automatically fetch primary color from the config file.
```elixir

**Then your component.button.ex file could look like this:**
```elixir
defmodule MyApp.Button do
  use Phoenix.Component
  import TailColors
  @sizes ~w"xs sm md lg xl"
  @styles ~w"classic outline"
  @default_color Map.get(Application.compile_env(:tail_colors, :themed_colors), :primary)
  @default_tint 700

  attr :class, :string, default: ""
  attr :rest, :gobal
  slot :inner_block, required: true
  def button(assigns) do
    ~H"""
    <button class={parse_class(@class)} {@rest}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  defp parse_class(class_str) do
    class_str = theme(class_str)
    l = String.split(class_str, ~r/\s+/)

    size = get(l, @sizes, "md")
    style = get(l, @styles, "classic")
    {color, tint} = main_color(l, @default_color, @default_tint)

    [case size do
      "xs" -> "px-2.5 py-1.5 text-xs"
      "sm" -> "px-3 py-2 text-sm"
      "md" -> "px-4 py-2 text-md"
      "lg" -> "px-4 py-2 text-lg"
      "xl" -> "px-6 py-3 text-xl"
    end]
    ++
    case style do
      "classic" ->
        [
          get(l, "bg", color, tint),
          "hover:#{get(l, "bg", color, tint) |> darker(2)}",
          get(l, "ring", color, tint),
          get(l, "text", color, invert(tint))
        ]
        "outline" ->
          [
            "hover:#{get(l, "bg", color, tint)} hover:#{get(l, "text", color, tint) |> invert()}",
            get(l, "ring", color, tint),
            "border #{get(l, "border", color, tint)}",
            get(l, "text", color, tint)
          ]
    end
    ++ [
          clean(class_str, @sizes ++ @styles)
          |> clean_prefix(~w"bg text, ring")
          |> clean_colors()
    ]
  end
end
```

OK, let's walk through that together.  At the top of the module, we import TailColors, and set the accepted options for size and styles.  We also set the default_color to pull from the primary attribute from the config.  Finally, we set the default_tint.

Next, we have a standard button component, however, in the class attribute, we're calling the parse_class function, and passing in the class string.

The parse_class function is where all of our major logic lies.  The first thing that we do is we replace the class_str with the theme(class_str).  This function simply looks through all the classes and replaces any themed_colors with their corresponding values.  So in the example above, since we set primary to purple in the config, the class_str would be replaced with "purple box xl".

Next, we create a list out of the class_str.  Technically speaking, each of the functions in TailColors can accept either a string or a list, however, since all the functions just convert the string into a list anyways, we'll save ourselves some cpu's and just pass in the list.

This is where things start to get interesting.  We use the `get/3` function to find out if any of the known sizes defined in @sizes is present in the class list.  If it is, we set the size variable to that value, otherwise, we set it to the default value that's passed in the third parameter, in this case: "md".  We do the same thing for style, except we look for the values in @styles.

The `main_color/3` function looks through the class list for any defined colors, either default colors that come with tailwind, or custom colors that you've defined in your tailwind.config.js file.  If it finds a color, it returns the color, and the tint in a tuple.  If it doesn't find a color, it returns the default_color and default_tint which are passed in as the second and third arguments.

in the example above, the only color that was passed in was 'primary', which was replaced by "purple" by the theme function, and there's no tint so the default tint is used, which in this case is `700`.  If a tint was passed in, such as `primary-200`, then the `200` would have been returned as the tint.

Next, we start building out the list of strings that we are going to return.  Phoenix will convert this list into a string, so it will be an accepted class attribute.  The `case` statement around size is pretty self-explanatory.  However, the case for style is way more interesting.

TailColors' `get/4` function takes the class list, a prefix to use as an identifier and a default value to use for the color and the tint.  The function will then search through the class list looking for any classes that start with the prefix, if it finds the prefix, it returns the full class name: `prefix-color-tint`.  If it doesn't find the prefix, it returns the default value with the prefix.  Here are a few examples:
```elixir
get(~w"one bg-red-100 two", "bg", "blue", 500)
"bg-red-100"

get(~w"one bg-red two", "bg", "blue", 500)
"bg-red-500"

get(~w"one two", "bg", "blue", 500)
"bg-blue-500"
```

This means that we can **OVERIDE** the default color and tint by passing in a class name that starts with the prefix. This works for any standard tailwind classname that follows the `prefix-color-tint` model.  In the example button component above, the `get/4` function is looking to see if there is a classname that matches `text-color-tint`, and if there is, it uses that value, otherwise, it uses the default color and tint.

Next, there's a weird `"hover:#{get(l, "bg", color, tint) |> darker(2)}"` line of code.  This is using string interpolation to build out the hover class.  The `get/4` function we've already talked about.  But the `darker/2` function is new.  It takes a standard tailwind class in the `prefix-color-tint` format, and the number of steps on the tailwind color tint array to use.  Here's some examples:
```elixir
darker("text-red-600", 2)
"text-red-800"

darker("ring-red-600", 8)
"ring-red-950"
```
Notice when we try to step past the darkest shade, it just returns the darkest shade available.  As you can probably guess, there's also a `lighter/2` function that works the same way.

Finally, there's the `invert/1` function.  This function takes a tailwind prefix-color-tint class, and returns the inverted color tint class.  For example:
```elixir
invert("text-red-600")
"text-red-50"

invert("text-red-100")
"text-red-500"
```
The `invert/1` function is primarily used to invert the text color for better readability.

## HELP! I'm not seeing my changes take effect!

Tailwind looks for known classes to appear in your application's source code.  However, our source code is using dynamically generated class names.  So tailwind doesn't know to include it in the final css file.  To fix this, we need to add the following to our tailwind.config.js file:
```javascript
safelist: [
  "text-red-600",
  "ring-blue-400",
  "hover:ring-blue-600",
  ...
]
```
@@TODO:
Created a mix task that will automatically generate a list of all the classes that are used in your application.
```elixir

## License

MIT License

----
Created:  2023-11-06Z
