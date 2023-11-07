defmodule TailColors do
  @compile :export_all

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
          ] ++ Application.compile_env(:tail_colors, :colors) || []

  @tints [50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950]
  @themed_colors Application.compile_env(:tail_colors, :themed_colors) || %{}

  @doc ~S"""
    substitutes a themed color from config for the actual color name.

    ## Examples
      iex> TailColors.theme "one primary two"
      "one purple two"

      iex> TailColors.theme "text-info-400"
      "text-sky-400"

      iex> TailColors.theme("one green-400 two")
      "one green-400 two"
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
  """
  def get(classes, prefix) when is_bitstring(classes), do: get(String.split(classes, " "), prefix)

  def get(classes, prefix) when is_bitstring(prefix) do
    classes
    |> Enum.find(fn class -> String.starts_with?(class, prefix <> "-") end)
  end

  def get(classes, list) when is_list(list), do: common_items(classes, list)

  @doc ~S"""
  takes a list of classNames and a string, and returns true if the string is in the list

  ## Examples

  iex> TailColors.has?("thing text-red-400 something", "something")
  true

  iex> TailColors.has?("thing bg-blue", "something")
  false
  """
  def has?(classes, str) when is_bitstring(classes),
    do: has?(String.split(classes, " "), str)

  def has?(classes, str) when is_bitstring(str) do
    classes
    |> Enum.any?(&String.starts_with?(&1, str))
  end

  @doc ~S"""
  takes a list of classNames and a string, and returns true if the string is in the list

  ## Examples

  iex> TailColors.main_color("thing red something")
  "red"

  iex> TailColors.main_color("thing silver-hawk something")
  "silver-hawk"

  iex> TailColors.main_color("thing silver-hawk-400 something")
  "silver-hawk-400"

  iex> TailColors.main_color("thing something")
  nil
  """
  def main_color(classes) when is_bitstring(classes), do: main_color(String.split(classes, " "))

  def main_color(classes) when is_list(classes) do
    case(common_items(classes, @colors)) do
      nil -> with_tints(classes)
      match -> match |> hd
    end
  end

  defp with_tints(classes) when is_bitstring(classes), do: with_tints(String.split(classes, " "))

  defp with_tints(classes) do
    classes
    |> Enum.map(&parse_color_tint/1)
    |> Enum.find(fn
      {_color, nil} -> false
      {color, tint} -> color in @colors and tint in @tints
    end)
    |> case do
      {c, t} -> "#{c}-#{Integer.to_string(t)}"
      nil -> nil
    end
  end

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
end
