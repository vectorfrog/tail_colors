defmodule TailColors do
  @moduledoc """
  Helper functions for working with tailwind classes
  """
  alias Twix

  defdelegate tw(classes), to: Twix, as: :tw

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
  takes class string and returns all classes that start with the prefix.

  ## Examples
      iex> TailColors.get_prefix("thing title-text-red-500 something", "title")
      "text-red-500"
  """
  def get_prefix(class, prefix) when is_bitstring(class), do: get_prefix(break(class), prefix)

  def get_prefix(class, prefix) do
    Enum.filter(class, &String.starts_with?(&1, prefix))
    |> Enum.map(fn item -> String.replace(item, prefix <> "-", "") end)
    |> Enum.join(" ")
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

  defp break(class_list), do: String.split(class_list, ~r/\s+/)

  defp first_prefix(cl, prefix), do: Enum.find(cl, &String.starts_with?(&1, prefix <> "-"))

  defp common_items(l1, l2) do
    l3 = l1 -- l2

    (l1 -- l3)
    |> case do
      [] -> nil
      match -> match
    end
  end
end
