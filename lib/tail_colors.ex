defmodule TailColors do
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
  takes a list of classNames and returns the first class that starts with a string followed by a -

  ## Examples

  iex> TailColors.get("thing text-red-400 something", "text")
  "text-red-400"

  iex> TailColors.get("thing bg-blue", "bg")
  "bg-blue"

  iex> TailColors.get("thing else", "bg")
  nil

  iex> TailColors.get("thing bg-monster else", "bg")
  nil

  iex> TailColors.get("thing bg-blue-404 else", "bg")
  nil

  iex> TailColors.get("thing box else", ["circle", "rounded", "box"])
  "box"
  """
  def get(classes, prefix) when is_bitstring(classes), do: get(break(classes), prefix)

  def get(classes, prefix) when is_bitstring(prefix) do
    classes
    |> Enum.find(fn class -> String.starts_with?(class, prefix <> "-") end)
    |> color_tint(prefix)
  end

  def get(classes, list) when is_list(list) do
    case common_items(classes, list) do
      nil -> nil
      [h | _] -> h
    end
  end

  defp color_tint(nil, _), do: nil

  defp color_tint(class, prefix) do
    if is_color?(class, prefix) and is_tint?(class) do
      class
    else
      nil
    end
  end

  defp is_color?(class, prefix) do
    case String.split(class, "-") do
      [^prefix, color] -> color in @colors
      [^prefix, color, _] -> color in @colors
      _ -> false
    end
  end

  defp is_tint?(class) do
    with [str | _] <- String.split(class, "-") |> Enum.reverse(),
         {int, _} <- Integer.parse(str) do
      int in @tints
    else
      _ -> false
    end
  end

  @doc """
  takes a list of classNames and matches the first class with the prefix and returns a color tuple

  ## Examples

  iex> TailColors.get_tuple("thing text-red-400 something", "text")
  {"text-red", 400}

  iex> TailColors.get_tuple("thing text-red something", "text")
  {"text-red", nil}

  iex> TailColors.get_tuple("thing something", "text")
  nil
  """
  def get_tuple(class_str, prefix) when is_bitstring(class_str),
    do: get_tuple(break(class_str), prefix)

  def get_tuple(class_list, prefix) when is_list(class_list) and is_bitstring(prefix) do
    get(class_list, prefix)
    |> parse_color_tint()
  end

  @doc """
  takes a list of classNames and matches the first class with the prefix and returns the match or default values

  ## Examples

  iex> TailColors.get("thing text-red-400 something", "text", "blue", 600)
  "text-red-400"

  iex> TailColors.get("thing text-red something", "text", "blue", 600)
  "text-red-600", nil

  iex> TailColors.get("thing something", "text", "blue", 600)
  "text-blue-600"
  """
  def get(class_str, p, c, t) when is_bitstring(class_str), do: get(break(class_str), p, c, t)

  def get(class_list, prefix, default_color, default_tint) do
    case get(class_list, prefix) do
      nil ->
        "#{prefix}-#{default_color}-#{default_tint}"

      match ->
        parse_color_tint(match)
        |> IO.inspect(label: "parse")
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

  iex> TailColors.main_color("thing red something")
  {"red", nil}

  iex> TailColors.main_color("thing red-400 something")
  {"red", 400}

  iex> TailColors.main_color("thing something")
  nil
  """
  def main_color(classes) when is_bitstring(classes), do: main_color(break(classes))

  def main_color(classes) when is_list(classes) do
    case(common_items(classes, @colors)) do
      nil ->
        with_tints(classes)

      match ->
        color = match |> hd
        {color, nil}
    end
  end

  defp with_tints(classes) do
    classes
    |> Enum.map(&parse_color_tint/1)
    |> Enum.find(fn
      {_color, nil} -> false
      {color, tint} -> color in @colors and tint in @tints
    end)
  end

  defp parse_color_tint(nil), do: nil

  defp parse_color_tint(class) do
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
          {[h | t] |> Enum.reverse() |> Enum.join("-"), nil}
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

  @doc ~S"""
    moves the tint down the list of tints.

    ## Examples
      iex> TailColors.darker(600, 1)
      700

      iex> TailColors.darker(600, 3)
      900

      iex> TailColors.darker(600, 9)
      950
  """
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
  """
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

  def clean(class_list, remove_list) when is_bitstring(class_list),
    do: clean(break(class_list), remove_list)

  def clean(class_list, remove_list) when is_bitstring(remove_list),
    do: clean(class_list, break(remove_list))

  def clean(class_list, remove_list) do
    (class_list -- remove_list) |> Enum.filter(& &1) |> Enum.join(" ")
  end

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
