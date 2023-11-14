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

Tailcolors uses a fork of the excellent [Twix library](https://github.com/vectorfrog/twix).  If you are using custom colors in your tailwind.config.js file, (and I strongly recommend that you do and use themeable names like "primary", "secondary", "accent", "success", "error"...etc) you can add those colors so they will identified as colors to identify in your class names:
```elixir
import Config

config :twix,
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

TailColors provides a few functions to help you build out your own components where you pass in data through the class attribute.  For example, if you want to build a button component, you can pass in the style, and size of the button through the class attribute, and then use TailColors to parse out the data, and modify the classes.

#### home_live.html.leex
```
<.button class="outline xl">Hello</.button>
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
    <button class={tw([size(@class), style(@class), clean(@class, @sizes ++ @styles)])} {@rest}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  def size("xs"), do: "px-2.5 py-1.5 text-xs"
  def size("sm"), do: "px-3 py-2 text-sm"
  def size("md"), do: "px-4 py-2 text-md"
  def size("lg"), do: "px-4 py-2 text-lg"
  def size("xl"), do: "px-6 py-3 text-xl"
  def size(class), do: get(class, @sizes, "md")

  def style("classic"), do: "bg-red-600 hover:bg-red-700 ring-red-700 text-white"
  def style("outline"), do: "hover:bg-red-50 ring-red-700 text-red-600 border border-red-600"
  def style(class), do: get(class, @sizes, "classic")
end
```

OK, let's walk through that together.  At the top of the module, we import TailColors, and set the accepted options for size and styles.

Next, we have a standard button component, however, in the class attribute, we're calling the `tw/1` function, which is provided by twix, and will merge the list of classes that we pass in with the default classes that we define in the `button/1` function.  This allows us to override any of the default styles with any classes that are explicitly set in the class attribute.

We create a list inside the `tw/1` function.  This simply will add spaces between each item in the list.  The first item in the list is the `size/1` function, the second item is the `style/1` function, and the third item is the `clean/2` function.  The `clean/2` function will remove both the style and the size values from the class string. This is a good practice to avoid polluting the class string with values that are no longer needed, or worse, might alter the display of the element unintentionally.

For both the `size/1` and `style/1` functions, we simply pattern match against the class string, and return the appropriate value.  If the class string doesn't match any of the patterns, the last function parses the class string using the `get/3` function to determine if the class string has any of the values defined in the @sizes or @styles module attributes. If the class string doesn't contain any of the accepted values, then a default value is used.

Now let's take a look at another example that uses nested elements to create a more complex component.

```elixir
<.card class="box bg-gray-50 title-text-xl content-text-blue-800">
  <:title>My Example Card</:title>
  This is an example Card!  It has a title, and some content.
</.card>
```

```elixir
defmodule RentalsWeb.LayoutComponents.Card do
  import TailColors
  use Phoenix.Component

  @styles ~w(box rounded)
  @elements ~w(title content actions)

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)
  slot :inner_block, required: true
  slot :title, required: false
  def card(assigns) do
    ~H"""
    <div class={tw(["relative flex flex-col", style(@class), clean_class(@class)])} {@rest}>
      <div class="p-4 flex flex-col gap-4">
        <h2 class={tw(["flex bold text-2xl -mb-8", get_prefix(@class, "title")])}>
          <%= render_slot(@title) %>
        </h2>

        <div class={get_prefix(@class, "content")}>
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    </div>
    """
  end

  defp clean_class(class), do: clean(class, @styles) |> clean_prefix(@elements)

  def style("box"), do: ""
  def style("rounded"), do: "rounded-md"
  def style(class), do: style(get(class, @styles, "rounded"))
end
```

In the example above, we have a more complex components that has both a title slot and a content slot.  We are again using a list of style names, "box" and "rounded", that will determine the corners of the card.  However, if something like "rounded-2xl" were passed in the class string, that would override the default "rounded-md" value.

We also have a list of elements that we use to determine the class names for the title and content slots.  If the class string starts with "title-", then the div that wraps the title slot will add that class to the div using the `get_prefix/2` function.  In the example above, the "title-text-xl" will override the default "text-2xl" value.

The "content-text-blue-800" will be transformed into "text-blue-800" and added to the div that wraps the inner_block slot.

The `get_prefix/2` function gives us an easy way to style nested elements without having to create a bunch of props.  It also keeps all of the styling information in the class attribute, which makes it easier to see what styles are being applied.

Finally, we are using the `clean/2` function to remove all the style and element prefixes from the class string.  So the final result will be:

```html
    <div class="relative flex flex-col">
      <div class="p-4 flex flex-col gap-4">
        <h2 class="flex bold text-xl -mb-8">
          My Example Card
        </h2>

        <div class="text-blue-800">
          This is an example Card!  It has a title, and some content.
        </div>
      </div>
    </div>
```

#### Hey! I don't see my classes take effect!

Tailwind searches files for known class names.  Unfortunately, it doesn't recognize class names that are dynamically generated.  So it won't identify "content-text-blue-800" even though that will get transformed to "text-blue-800" later on. You will need to add any dynamically generated class names to your tailwind.config.js file.  For the example above, you would add the following to your tailwind.config.js:
```javascript
module.exports = {
  ...,
  safelist: ["text-blue-800"]
}
```

If that's too much work, you can do the lazy dev's approach and just throw a commented html string into your call to the component:
```elixir
<!-- text-blue-800 -->
<.card class="box bg-gray-50 title-text-xl content-text-blue-800">
  <:title>My Example Card</:title>
  This is an example Card!  It has a title, and some content.
</.card>
```
A good workflow is to use the HTML comments during development, and then before you publish, do a quick search for all the comments and add them to your tailwind.config.js file's safelist.
## License

MIT License

----
Created:  2023-11-06Z
