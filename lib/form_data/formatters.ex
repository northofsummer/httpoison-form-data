defmodule FormData.Formatters do
  @moduledoc """
  This module defines the `FormData.Formatters` behaviour.
  """

  @doc """
  This function takes three arguments, `name`, `value`, and `file` and returns a
  list of the partially formatted data.

  The List is an important part of the formatting process because it can easily
  be converted into a number of other formats (for example, a string) in the
  output function.
  """
  @callback format(name :: String.t, value :: String.t, file :: boolean) :: list(any)

  @doc """
  This function takes the list output from `FormData.Formatters.format` and a
  keyword list of options and produces the end-result desired (for example, a
  string).
  """
  @callback output(data :: list(any), options :: keyword(boolean)) :: any
end
