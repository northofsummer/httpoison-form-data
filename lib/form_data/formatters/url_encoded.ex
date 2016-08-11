defmodule FormData.Formatters.URLEncoded do
  @behaviour FormData.Formatters

  @doc ~S"""
  Format `name` and `value` as a key-value tuple.

  When the name or value of a parameter are absent, the parameter is ignored.
  When the `file` variable is present, the parameter is ignored.

  It returns a list of name-value tuples.

  ## Examples

    iex> FormData.Formatters.URLEncoded.format("Name", "Value", false)
    {"Name", "Value"}

    iex> FormData.Formatters.URLEncoded.format("Name", "Value", true)
    nil

    iex> FormData.Formatters.URLEncoded.format("", "Value", false)
    nil

    iex> FormData.Formatters.URLEncoded.format("Name", "", false)
    nil

    iex> FormData.Formatters.URLEncoded.format(nil, "Value", false)
    nil

    iex> FormData.Formatters.URLEncoded.format("Name", nil, false)
    nil

    iex> FormData.Formatters.URLEncoded.format("Name", "Value", nil)
    nil

  """
  def format("", _, _), do: nil
  def format(_, "", _), do: nil
  def format(nil, _, _), do: nil
  def format(_, nil, _), do: nil
  def format(_, _, nil), do: nil
  def format(_, _, true), do: nil
  def format(name, value, false), do: {"#{name}", "#{value}"}

  @doc ~S"""
  Format a `list` of key-value tuples for URL Encoded requests.

  Since URLEncoded parameters can be used in GET and POST requests, the
  `options` hash includes a `:get` option. The default output is valid form
  data for a call to `HTTPoison.post`. The output with the `:get` flag is valid
  data for a call to `HTTPoison.get`.

  If a different HTTP library is in use, or if the URL string needs to be
  modified, the `:url` flag can be set to output the proper URL string.

  ## Examples

    iex> FormData.Formatters.URLEncoded.output([{"Name", "Value"}, {"Name2", "Value2"}], [])
    {:form, [{"Name", "Value"}, {"Name2", "Value2"}]}

    iex> FormData.Formatters.URLEncoded.output([{"Name", "Value"}, {"Name2", "Value2"}], get: true)
    [params: [{"Name", "Value"}, {"Name2", "Value2"}]]

    iex> FormData.Formatters.URLEncoded.output([{"Name", "Value"}, {"Name2", "Value2"}], url: true)
    "?Name=Value&Name2=Value2"

  """
  def output([], [url: true]), do: ""
  def output([], [get: true]), do: [params: []]
  def output([], _opts), do: {:form, []}
  def output(list, [url: true]) do
    str = list
      |> Enum.map(fn {name, value} ->
        name <> "=" <> value
      end)
      |> Enum.join("&")

    "?" <> str
  end
  def output(list, [get: true]), do: [params: list]
  def output(list, _opts), do: {:form, list}

end
