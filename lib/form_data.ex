defmodule FormData do
  @moduledoc """
  This module contains the recursive traversal algorithm used to build properly
  formatted names for both multipart and urlencoded requests.
  """

  defmodule Error do
    @moduledoc """
    This is the generic FormData error. It should only be triggered when the
    data passed in is not a Keyword List, Map, or Struct.
    """
    defexception [:message]

    def exception(value) do
      msg = "expected Struct, Map, or Keyword, got: #{inspect value}"
      %__MODULE__{message: msg}
    end
  end

  defmodule File do
    defstruct path: ""
  end

  @formatters %{
    multipart: FormData.Formatters.Multipart,
    url_encoded: FormData.Formatters.URLEncoded
  }

  @doc """
  This function chooses the correct `formatter` and uses it in conjunction with
  the recursive name-formatting algorithm to produce the desired data structure.

  The built-in formatters are Multipart and URLEncoded, but a 3rd-party
  formatter that is a behaviour of FormData.Formatter can be passed in as well.
  """
  @spec create(obj :: keyword | map | struct, formatter :: atom, output_opts :: keyword(boolean)) :: {:ok, any} | {:error, String.t}
  def create(obj, formatter, output_opts \\ [])
  def create(obj, formatter, output_opts) when is_list(obj) or is_map(obj) do
    obj = try do
      ensure_keyword(obj) # Error in here if not a keyword list
    rescue
      _ -> {:error, Error.exception(obj)}
    end

    case obj do
      {:error, _}=error -> error
      _ -> {:ok, do_create(obj, formatter, output_opts)}
    end
  end
  def create(obj, _formatter, _output_opts) do
    {:error, Error.exception(obj)}
  end

  @doc """
  This function chooses the correct `formatter` and uses it in conjunction with
  the recursive name-formatting algorithm to produce the desired data structure.

  The built-in formatters are Multipart and URLEncoded, but a 3rd-party
  formatter that is a behaviour of FormData.Formatter can be passed in as well.
  """
  @spec create!(obj :: keyword | map | struct, formatter :: atom, output_opts :: keyword(boolean)) :: {:ok, any} | {:error, String.t}
  def create!(obj, formatter, output_opts \\ [])
  def create!(obj, formatter, output_opts) when is_list(obj) or is_map(obj) do
    obj = try do
      ensure_keyword(obj) # Error in here if not a keyword list
    rescue
      _ -> raise Error, obj
    end

    do_create(obj, formatter, output_opts)
  end
  def create!(obj, _formatter, _output_opts) do
    raise Error, obj
  end

  # do_create is the generic sequence of the logic in this project.
  # When do_create is called, we assume that `obj` is a Keyword List.
  # First, it determines the correct formatter to use, then it generates the
  # required data structure with to_form's recursive traversal with a chained
  # nil-removal filter (in the same pass because streams).
  #
  # Finally, it passes a list to the output formatter.
  defp do_create(obj, formatter, output_opts) do
    f = Map.get(@formatters, formatter) || formatter

    obj
    |> to_form(f)
    |> Stream.filter(&not_nil(&1))
    |> Enum.to_list
    |> f.output(output_opts)
  end

  # Ensure keyword attempts to coerce a map or list into a keyword list. If this
  # is not possible, it errors.
  defp ensure_keyword(list) when is_list(list) do
    Enum.map(list, fn {k, v} ->
      {k, v}
    end)
  end
  defp ensure_keyword(map) when is_map(map) do
    map
    |> Map.delete(:__struct__)
    |> Map.to_list
  end

  # this is the entry point. We start the to_form recursion by initializing each
  # name to an empty string. we call pair_to_form as the callback rather than
  # nested_pair_to_form because we don't want the names at this point to be in
  # brackets.
  #
  # input:          %{"key" => "value"}, formatter
  # recursing call: to_form("value", "key", formatter)
  #
  # input:          %{"key" => [ "value1", "value2" ]}, formatter
  # recursing call: to_form([ "value1", "value2" ], "key", formatter)
  defp to_form(obj, formatter) do
    Stream.flat_map(obj, &pair_to_form(&1, "", formatter))
  end

  # when we encounter a File struct as a value, we have reached the max depth of
  # this tree, return the formatted data in an array. The array is important
  # because it is flat_map'd out of the array. This function must come before
  # the declaration of the is_map because structs will return true for is_map.
  defp to_form(%File{path: path}, name, formatter) do
    [formatter.format(name, path, true)]
  end

  # When we have a nested map, we want to call nested_pair_to_form on each
  # key/value pair.
  #
  # input:          %{"key" => "value"}, "outer_key", formatter
  # recursing call: to_form("value", "outer_key[key]", formatter)
  defp to_form(obj, name, formatter) when is_map(obj) do
    obj
    |> ensure_keyword
    |> Stream.flat_map(&nested_pair_to_form(&1, name, formatter))
  end

  # Tuples are converted to lists, since they behave similarly.
  defp to_form(obj, name, formatter) when is_tuple(obj) do
    Tuple.to_list(obj)
    |> to_form(name, formatter)
  end

  # Lists are simply iterated across. We append `[]` to the name provided.
  #
  # input:          ["value1", "value2", "value3"], "outer_key", formatter
  # recursing call: [to_form("value1", "outer_key[]", formatter),
  #                  to_form("value2", "outer_key[]", formatter),
  #                  to_form("value3", "outer_key[]", formatter)]
  defp to_form(obj, name, formatter) when is_list(obj) do
    Stream.flat_map(obj, &to_form(&1, name <> "[]", formatter))
  end

  # When we have a value that does not fit the above conditions, we assume
  # we have reached a value that is not a nested data structure and therefore
  # can safely pass it to the provided formatter.
  defp to_form(value, name, formatter) do
    [formatter.format(name, value, false)]
  end

  defp pair_to_form({k, v}, name, formatter) do
    to_form(v, name <> "#{k}", formatter)
  end

  defp nested_pair_to_form({k, v}, name, formatter) do
    to_form(v, name <> "[#{k}]", formatter)
  end

  defp not_nil(nil), do: false
  defp not_nil(_), do: true

end
