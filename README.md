# TailColors

This library is a collection of useful functions for working with tailwind colors.  It is meant to be a helper library if you're building out your own custom components that utilizes class names to key logic off of.  The paradigm is heavily influenced by [DaisyUI](https://daisyui.com/components/button/), however, you must create the components.

The main advantage of this approach is that you can create complex components with nested elements, and then easily pass in style overrides for those NESTED elements in the class string, instead of having to build out dozens of props. or tons of slots.  Also, it keeps all styling information in the class attribute.  This makes it easier to see what styles are being applied. Props then can be used for data, and slots can be used for content.
```elixir
<.hero class="bg-blue-500 panel-white btn-xl btn-success btn-full">Hello</.hero>
```
vs
```elixir
<.hero class="bg-blue-500">
  <:panel>
    <div class="bg-white">
      Hello
    </div>
  </:panel>
    <:action>
      <.button class="bg-green-700 text-xl w-full"></.button>
    </:action>
  Hello</.hero>
```
vs
```elixir
<.hero class="bg-blue-500" panel_color="white" btn_color="bg-success" btn_size="xl" btn_width="full">Hello</.hero>
```
## Installation

```elixir
@deps [
tail_colors: "~> 0.1.0"
]
```
## Config

If you are using custom colors in your tailwind.config.js file, (and I strongly recommend that you do and use themeable names like "primary", "secondary", "accent", "success", "error"...etc) you can add those colors so they will identified as colors to identify in your class names:
```elixir
import Config

config :tail_colors,
  colors: [
    "primary",
    "secondary",
    "accent",
    "info",
    "success",
    "warning",
    "error",
    "base"
  ],
```

## Usage

TailColors provides a few functions to help you build out your own components where you pass in data through the class attribute.  For example, if you want to build a button component, you can pass in the color, style, and size of the button through the class attribute, and then use TailColors to parse out the data, and modify the classes.

#### home_live.html.leex
```
<.button class="box xl">Hello</.button>
```
#### lib/my_app_web/components/button.ex
```
defmodule MyApp.Button do
  use Phoenix.Component
  import TailColors
  @sizes ~w"xs sm md lg xl"
  @styles ~w"classic outline"

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
    l = String.split(class_str, ~r/\s+/)

    size = get(l, @sizes, "md")
    style = get(l, @styles, "classic")

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
          get_color(l, "bg", "bg-red-600"),
          get_color(l, "hover:bg", "bg-red-700"),
          get_color(l, "ring", "ring-red-700"),
          get_color(l, "text", "text-white")
        ]
      "outline" ->
        [
          get_color(l, "hover:bg", "hover:bg-red-50"),
          get_color(l, "text", "text-red-600"),
          get_color(l, "ring", "ring-red-700"),
          "border #{get_color(l, "border", "border-red-600")}",
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

The parse_class function is where all of our major logic lies. We create a list out of the class_str.  Technically speaking, each of the functions in TailColors can accept either a string or a list, however, since all the functions just convert the string into a list anyways, we'll save ourselves some cpu's and just pass in the list.

This is where things start to get interesting.  We use the `TailColors.get/3` function to find out if any of the known sizes defined in *@sizes is present in the class list.  If it is, we set the size variable to that value, otherwise, we set it to the default value that's passed in the third parameter, in this case: "md".  We do the same thing for style, except we look for the values in @styles.

Next, we start building out the list of strings that we are going to return.  The `case` statement around size is pretty self-explanatory.  However, the case for style is way more interesting.

`TailColors.get_color/3` function takes the class list, a prefix to use as an identifier and a default value.  The function will then search through the class list looking for any classes that start with the prefix, if it finds the prefix, it returns the full class name: `prefix-color-tint`.  If it doesn't find the prefix, it returns the default value.  Here are a few examples:

This means that we can **OVERIDE** the default color by passing in a class name that starts with the prefix. This works for any standard tailwind classname that follows the `prefix-color-tint` model.  In the example button component above, the `get_color/3` function is looking to see if there is a classname that matches `text-color-tint`, and if there is, it uses that value, otherwise, it uses the default color provided.

At the bottom of the `parse/1` function, there are several `clean` functions.  These functions remove classnames from the class string to avoid polluting the class string.  For instance, once we've identified the "outline" style, we don't want "outline" to appear in our class string, on the off chance that somewhere else, there is an "outline" css class.  However, we may want that, so you can choose to use the clean functions or not.

`TailColors.clean/2` takes the class string, and a list of classnames to remove from the class string.  `TailColors.clean_prefix/2` takes the class string, and a list of prefixes to remove from the class string.  `TailColors.clean_colors/1` takes the class string, and removes any stand alone color classes from the class string.

I would recommend using the `TailColors.clean_prefix/2` function if you are using any interpolated classes, such as "hover:bg-red-600" where the color and tint are provided in the "bg-red-600" in the class name.  Otherwise, you'll end up with "hover:bg-red-600 bg-red-600" in your class string, which will cause the background to always be red! instead of just on hover.

## License

MIT License

----
Created:  2023-11-06Z
