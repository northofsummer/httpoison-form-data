defmodule FormData.Formatters.Multipart do
  @behaviour FormData.Formatters

  @doc """
  The Multipart output function wraps the output of `format` in a structure
  denoting to HTTPoison (and hackney) that the data to be submitted is
  multipart.

  ## Examples

      iex> FormData.Formatters.Multipart.output([{:key, "one"}], [])
      { :multipart, [{ "", "one", { "form-data", [ {"name", "\\"key\\""} ] }, [] }] }

  """
  def output(stream, _opts) do
    list = stream
      |> Stream.map(fn
        {k, %FormData.File{path: path}} -> format(k, path, true)
        {k, v} -> format(k, v, false)
      end)
      |> Enum.to_list

    {:multipart, list}
  end

  defp format(name, path, true) do
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
  defp format(name, value, false) do
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

end
