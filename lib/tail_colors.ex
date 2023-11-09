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
            "rose"
          ] ++ (Application.compile_env(:tail_colors, :colors) || [])

  @tints [50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950]
  @themed_colors Application.compile_env(:tail_colors, :themed_colors) || %{}

  @doc ~S"""
  substitutes a themed color from config for the actual color name.
  """
  def theme(class_str) do
    Map.keys(@themed_colors)
    |> Enum.map(&Atom.to_string/1)
    |> Enum.reduce(class_str, fn item, new_str ->
      String.replace(new_str, item, Map.get(@themed_colors, String.to_atom(item)))
    end)
  end

  @doc ~S"""
  takes list of classNames and starting text, and finds first instance
  that matches with a known color and tint, a default value can also be set
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
  """
  def get_color(classes, lookup, default \\ nil)

  def get_color(classes, p, d) when is_bitstring(classes), do: get_color(break(classes), p, d)

  def get_color(classes, prefix, default) when is_bitstring(prefix) do
    classes
    |> Enum.find(fn class -> String.starts_with?(class, prefix <> "-") end)
    |> color_tint(prefix)
    |> case do
      nil -> default
      match -> match
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

  defp first_prefix(cl, prefix), do: Enum.find(cl, &String.starts_with?(&1, prefix <> "-"))

  @doc ~S"""
  takes a list of classNames and matches the first class with the prefix and returns the match or default values

  ## Examples
      iex> TailColors.get("thing text-red-400 something", "text", "blue", 600)
      "text-red-400"

      iex> TailColors.get("thing text-red something", "text", "blue", 600)
      "text-red-600"

      iex> TailColors.get("thing something", "text", "blue", 600)
      "text-blue-600"
  """

  def get(class_str, p, c, t)

  def get(class_str, p, c, t) when is_bitstring(class_str),
    do: get(break(class_str), p, c, t)

  def get(class_list, prefix, default_color, default_tint) do
    case get(class_list, prefix) do
      nil ->
        "#{prefix}-#{default_color}-#{default_tint}"

      match ->
        if int_ending?(match) do
          match
        else
          "#{match}-#{default_tint}"
        end
    end
  end

  defp color_tint(nil, _), do: nil

  defp color_tint(class, prefix) do
    cond do
      !is_color?(class, prefix) -> nil
      int_ending?(class) and !is_tint?(class) -> nil
      true -> class
    end
  end

  defp is_color?(class, prefix) do
    case String.split(class, "-") do
      [^prefix, color] -> color in @colors
      [^prefix, color, _] -> color in @colors
      _ -> false
    end
  end

  defp int_ending?(c), do: String.match?(c, ~r/.*-\d+/)

  defp is_tint?(class) do
    with [str | _] <- String.split(class, "-") |> Enum.reverse(),
         {int, _} <- Integer.parse(str) do
      int in @tints
    else
      _ -> false
    end
  end

  defp break(class_list), do: String.split(class_list, ~r/\s+/)

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
  takes a list of classNames and finds any colors that appear that are not prefixed by a string followed by a -
  returns a tuple of {color, tint}

  ## Examples
      iex> TailColors.main_color("thing red something", "blue", 700)
      {"red", 700}

      iex> TailColors.main_color("thing red-400 something", "blue", 700)
      {"red", 400}

      iex> TailColors.main_color("thing something", "blue", 700)
      {"blue", 700}
  """
  def main_color(classes, c, t) when is_bitstring(classes), do: main_color(break(classes), c, t)

  def main_color(classes, default_color, default_tint) when is_list(classes) do
    case(common_items(classes, @colors)) do
      nil ->
        case with_tints(classes, default_tint) do
          nil -> {default_color, default_tint}
          tuple -> tuple
        end

      match ->
        color = match |> hd
        {color, default_tint}
    end
  end

  defp with_tints(classes, default_tint) do
    classes
    |> Enum.map(&parse_color_tint(&1, default_tint))
    |> Enum.find(fn
      {_color, nil} -> false
      {color, tint} -> color in @colors and tint in @tints
    end)
  end

  defp parse_color_tint(nil, _), do: nil

  defp parse_color_tint(class, default_tint) do
    class
    |> String.split("-")
    |> Enum.reverse()
    |> case do
      [h | []] ->
        {h, nil}

      [h | t] ->
        if str_to_int(h) in @tints do
          {t |> Enum.reverse() |> Enum.join("-"), String.to_integer(h)}
        else
          {[h | t] |> Enum.reverse() |> Enum.join("-"), default_tint}
        end
    end
  end

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

  defp modify(class_str, mod_fun, args \\ []) do
    if is_tint?(class_str) do
      tint = get_tint(class_str)
      tint = apply(__MODULE__, mod_fun, [tint] ++ args)
      replace_tint(class_str, tint)
    else
      class_str
    end
  end

  defp replace_tint(c, tint) when is_integer(tint), do: replace_tint(c, Integer.to_string(tint))

  defp replace_tint(class_str, tint), do: Regex.replace(~r/-\d+$/, class_str, "-" <> tint)

  defp get_tint(str),
    do: str |> String.split("-") |> Enum.reverse() |> hd() |> String.to_integer()

  @doc ~S"""
  moves the tint down the list of tints.

  ## Examples
      iex> TailColors.darker(600, 1)
      700

      iex> TailColors.darker(600, 3)
      900

      iex> TailColors.darker(600, 9)
      950

      iex> TailColors.darker("text-green-400", 1)
      "text-green-500"

      iex> TailColors.darker("text-green-400", 9)
      "text-green-950"

      iex> TailColors.darker("not-a-tint", 1)
      "not-a-tint"
  """
  def darker(class_str, steps) when is_bitstring(class_str),
    do: modify(class_str, :darker, [steps])

  def darker(tint, steps), do: step(tint, steps)

  @doc ~S"""
  moves the tint up the list of tints.
  ## Examples
      iex> TailColors.lighter(600, 1)
      500

      iex> TailColors.lighter(600, 3)
      300

      iex> TailColors.lighter(600, 9)
      50

      iex> TailColors.lighter("text-green-400", 1)
      "text-green-300"

      iex> TailColors.lighter("text-green-400", 9)
      "text-green-50"

      iex> TailColors.lighter("not-a-tint", 1)
      "not-a-tint"
  """
  def lighter(class_str, steps) when is_bitstring(class_str),
    do: modify(class_str, :lighter, [steps])

  def lighter(tint, steps), do: step(tint, -1 * steps)

  defp step(tint, steps) when is_integer(tint) and is_integer(tint) do
    {_t, index} =
      Enum.with_index(@tints)
      |> Enum.find(fn {t, _i} -> t == tint end)

    cond do
      index + steps < 0 ->
        hd(@tints)

      true ->
        case Enum.fetch(@tints, index + steps) do
          {:ok, tint} -> tint
          :error -> List.last(@tints)
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

  @doc ~S"""
  takes a either a tint, or a color class, and returns a tint that is easier to read on that background
  #
  ## Examples
      iex> TailColors.invert(200)
      600
      iex> TailColors.invert("bg-blue-600")
      "bg-blue-50"
      iex> TailColors.invert(nil)
      nil
      iex> TailColors.invert("weirdo")
      "weirdo"
  """
  def invert(class_str)
  def invert(str) when is_bitstring(str), do: modify(str, :invert)
  def invert(nil), do: nil
  def invert(50), do: 400
  def invert(100), do: 500
  def invert(200), do: 600
  def invert(300), do: 700
  def invert(400), do: 50
  def invert(500), do: 50
  def invert(600), do: 50
  def invert(700), do: 100
  def invert(800), do: 100
  def invert(900), do: 200
  def invert(950), do: 300
end
