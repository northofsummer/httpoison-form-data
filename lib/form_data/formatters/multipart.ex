defmodule FormData.Formatters.Multipart do
  @behaviour FormData.Formatters

  @doc ~S"""
  The Multipart formatter formats a name and a filepath, or a name and a value
  correctly to be used in a list in an HTTPoison multipart request.

  It ignores parameters missing a name, value, or file indicator.

  ## Examples

    iex> FormData.Formatters.Multipart.format("Name", "some/file.path", true)
    { :file, "some/file.path", { "form-data", [ { "name", "\"Name\"" }, { "filename", "\"file.path\"" } ] }, [] }

    iex> FormData.Formatters.Multipart.format("Name", "Value", false)
    { "", "Value", { "form-data", [ { "name", "\"Name\"" } ] }, [] }

    iex> FormData.Formatters.Multipart.format("", "Value", false)
    nil

    iex> FormData.Formatters.Multipart.format("Name", "", false)
    nil

    iex> FormData.Formatters.Multipart.format(nil, "Value", false)
    nil

    iex> FormData.Formatters.Multipart.format("Name", nil, false)
    nil

    iex> FormData.Formatters.Multipart.format("Name", "some/file.path", nil)
    nil

  """
  def format("", _, _), do: nil
  def format(_, "", _), do: nil
  def format(nil, _, _), do: nil
  def format(_, nil, _), do: nil
  def format(_, _, nil), do: nil
  def format(name, path, true) do
    filename = Path.basename(path)

    {
      :file,
      path,
      {
        "form-data",
        [
          {"name", "\"#{name}\""},
          {"filename", "\"#{filename}\""}
        ]
      },
      []
    }
  end
  def format(name, value, false) do
    {
      "",
      value,
      {
        "form-data",
        [ {"name", "\"#{name}\""} ]
      },
      []
    }
  end

  @doc ~S"""
  The Multipart output function wraps the output of `format` in a structure
  denoting to HTTPoison (and hackney) that the data to be submitted is
  multipart.

  ## Examples

    iex> FormData.Formatters.Multipart.output(["one", "two"], [])
    {:multipart, ["one", "two"]}

  """
  def output(list, _opts), do: {:multipart, list}
end
