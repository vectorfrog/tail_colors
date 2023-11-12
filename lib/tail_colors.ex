defmodule TailColors do
  @moduledoc """
  Helper functions for working with tailwind classes
  """
  @colors [
            "slate",
            "gray",
            "zinc",
            "neutral",
            "stone",
            "red",
            "orange",
            "amber",
            "yellow",
            "lime",
            "green",
            "emerald",
            "teal",
            "cyan",
            "sky",
            "blue",
            "indigo",
            "violet",
            "purple",
            "fuchsia",
            "pink",
            "rose",
            "multi-dash-color-name"
          ] ++ (Application.compile_env(:tail_colors, :colors) || [])

  @tints [50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950]

  @doc ~S"""
  takes list of classNames and prefix text, and finds first instance
  that matches with a known color and tint, a default value should also be set
  ## Examples
      iex> TailColors.get_color("thing text-red-400 something", "text")
      "text-red-400"

      iex> TailColors.get_color("thing bg-blue", "bg")
      "bg-blue"

      iex> TailColors.get_color("thing else", "bg")
      nil

      iex> TailColors.get_color("thing bg-monster else", "bg")
      nil

      iex> TailColors.get_color("thing bg-blue-404 else", "bg")
      nil

      iex> TailColors.get_color("thing else", "bg", "bg-blue-600")
      "bg-blue-600"

      iex> TailColors.get_color("thing else", "bg", "bg-blue")
      "bg-blue"

  """
  def get_color(classes, prefix, default_color \\ nil)

  def get_color(classes, p, d) when is_bitstring(classes),
    do: get_color(break(classes), p, d)

  def get_color(classes, prefix, default) when is_bitstring(prefix) do
    color = Enum.find(classes, fn class -> String.starts_with?(class, prefix <> "-") end)

    cond do
      is_color_prefix?(color, prefix) ->
        color

      true ->
        default
    end
  end

  @doc ~S"""
  takes list of classNames and prefix text or list of options, and finds first instance that matches,
  a default value can also be set

  ## Examples
      iex> TailColors.get("thing rounded something", "rounded")
      "rounded"

      iex> TailColors.get("thing rounded-xl something", "rounded")
      "rounded-xl"

      iex> TailColors.get("thing else", "rounded")
      nil

      iex> TailColors.get("thing else", "rounded", "rounded-md")
      "rounded-md"

      iex> TailColors.get("thing box else", ["circle", "rounded", "box"])
      "box"

      iex> TailColors.get("thing else", ["circle", "rounded", "box"])
      nil

      iex> TailColors.get("thing else", ["circle", "rounded", "box"], "rounded")
      "rounded"
  """

  def get(classes, lookup, default \\ nil)
  def get(classes, prefix, d) when is_bitstring(classes), do: get(break(classes), prefix, d)

  def get(classes, prefix, default) when is_bitstring(prefix) do
    if prefix in classes do
      prefix
    else
      case first_prefix(classes, prefix) do
        nil -> default
        match -> match
      end
    end
  end

  def get(classes, list, default) when is_list(list) do
    case common_items(classes, list) do
      nil -> default
      [h | _] -> h
    end
  end

  @doc ~S"""
  takes a list of classNames and a string, and returns true if the string is in the list

  ## Examples
      iex> TailColors.has?("thing text-red-400 something", "something")
      true

      iex> TailColors.has?("thing bg-blue", "something")
      false
  """
  def has?(classes, str) when is_bitstring(classes),
    do: has?(break(classes), str)

  def has?(classes, str) when is_bitstring(str) do
    classes
    |> Enum.any?(&String.starts_with?(&1, str))
  end

  @doc ~S"""
  takes a single tailwind class and explodes it into a tuple of {prefix, color, tint}
  ## Examples
    iex> TailColors.explode("text-red-400")
    {"text", "red", 400}
    iex> TailColors.explode("multi-dash-color-name-500")
    {nil, "multi-dash-color-name", 500}
    iex> TailColors.explode("bg-blue")
    {"bg", "blue", nil}
    iex> TailColors.explode("woof")
    {nil, nil, nil}
    iex> TailColors.explode("woof-500")
    {nil, nil, nil}
    iex> TailColors.explode("woof-blue-500")
    {"woof", "blue", 500}
  """
  def explode(class) do
    tint = get_tint(class)
    prefix = get_prefix(class)
    color = explode_color(prefix, tint, class)

    cond do
      class in @colors ->
        {nil, class, nil}

      is_integer(tint) && no_prefix(class) in @colors ->
        {nil, no_prefix(class), tint}

      color == nil ->
        {nil, nil, nil}

      true ->
        case {prefix, color, tint} do
          {_, nil, _} -> {nil, nil, nil}
          {p, c, t} -> {p, c, t}
        end
    end
  end

  @doc ~S"""
  takes a list of classNames and a list of classes to remove, and then removes those classes if they appear in the classNames

  ## Examples
      iex> TailColors.clean("thing needle something", "needle")
      "thing something"
      iex> TailColors.clean("thing something", "needle")
      "thing something"
      iex> TailColors.clean("thing needle haystack something", "needle haystack")
      "thing something"
  """
  def clean(class_list, remove_list)
  def clean(cl, rl) when is_bitstring(cl), do: clean(break(cl), rl)
  def clean(cl, rl) when is_bitstring(rl), do: clean(cl, break(rl))

  def clean(class_list, remove_list) do
    (class_list -- remove_list) |> Enum.filter(& &1) |> Enum.join(" ")
  end

  @doc ~S"""
  takes a list of classNames and a list of classes to remove, and then removes those classes if they appear in the classNames

  ## Examples
      iex> TailColors.clean_prefix("thing bg-blue-500 something", "bg")
      "thing something"
      iex> TailColors.clean_prefix("thing something", "bg")
      "thing something"
      iex> TailColors.clean_prefix("thing bg-green-200 text-red-600 something", "bg text")
      "thing something"
  """
  def clean_prefix(class_list, remove_list)
  def clean_prefix(cl, rl) when is_bitstring(cl), do: clean_prefix(break(cl), rl)
  def clean_prefix(cl, rl) when is_bitstring(rl), do: clean_prefix(cl, break(rl))

  def clean_prefix(class_list, remove_list) do
    class_list
    |> Enum.filter(fn class ->
      !Enum.any?(remove_list, fn remove_class ->
        String.starts_with?(class, remove_class <> "-")
      end)
    end)
    |> Enum.join(" ")
  end

  @doc ~S"""
  takes a list of classNames and removes any colors that appear that do not follow the tailwind color struction prefix-color-tint
  #
  ## Examples
      iex> TailColors.clean_colors("thing blue something")
      "thing something"
      iex> TailColors.clean_colors("thing something")
      "thing something"
      iex> TailColors.clean_colors("thing blue red something")
      "thing something"
  """
  def clean_colors(class_list)
  def clean_colors(c) when is_bitstring(c), do: clean_colors(break(c))

  def clean_colors(class_list) do
    class_list
    |> Enum.filter(fn class ->
      !Enum.any?(@colors, fn color -> String.starts_with?(class, color <> "") end)
    end)
    |> Enum.join(" ")
  end

  defp break(class_list), do: String.split(class_list, ~r/\s+/)

  def is_color?(class) do
    case String.split(class, "-") do
      [color, tint] -> color in @colors and str_to_int(tint) in @tints
      [color] -> color in @colors
      _ -> false
    end
  end

  defp is_color_prefix?(nil, _prefix), do: false

  defp is_color_prefix?(class, prefix) do
    String.replace(class, prefix <> "-", "")
    |> String.split("-")
    |> case do
      [color, tint] -> color in @colors and str_to_int(tint) in @tints
      [color] -> color in @colors
      _ -> false
    end
  end

  defp first_prefix(cl, prefix), do: Enum.find(cl, &String.starts_with?(&1, prefix <> "-"))

  defp str_to_int(str) do
    case Integer.parse(str) do
      {int, _} -> int
      _ -> nil
    end
  end

  defp common_items(l1, l2) do
    l3 = l1 -- l2

    (l1 -- l3)
    |> case do
      [] -> nil
      match -> match
    end
  end

  defp no_prefix(class) do
    color = class |> String.split("-") |> Enum.slice(0..-2) |> Enum.join("-")

    if color in @colors do
      color
    else
      nil
    end
  end

  defp explode_color(prefix, tint, class)
  defp explode_color(nil, nil, class), do: explode_color_helper(is_color?(class), class)
  defp explode_color(nil, _t, class), do: explode_color_helper(class, 0..-2)
  defp explode_color(_p, nil, class), do: explode_color_helper(class, 1..-1)
  defp explode_color(_p, _t, class), do: explode_color_helper(class, 1..-2)

  defp explode_color_helper(true, class), do: class
  defp explode_color_helper(false, _class), do: nil

  defp explode_color_helper(class, range) when is_map(range) do
    color = class |> String.split("-") |> Enum.slice(range) |> Enum.join("-")

    if color in @colors do
      color
    else
      nil
    end
  end

  defp get_tint(str) do
    t = str |> String.split("-") |> Enum.reverse() |> hd() |> str_to_int()

    if t in @tints do
      t
    else
      nil
    end
  end

  defp get_prefix(str) do
    p = str |> String.split("-") |> hd()

    if !(p in @colors) do
      p
    else
      nil
    end
  end
end
