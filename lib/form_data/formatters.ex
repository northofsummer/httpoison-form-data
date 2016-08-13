defmodule FormData.Formatters do
  @moduledoc """
  This module defines the `FormData.Formatters` behaviour.
  """

  @doc """
  This function takes the stream output from `FormData.to_form`'s recursion and
  a keyword list of options and produces the end-result desired (for example, a
  string).
  """
  @callback output(data :: Enumerable.t, options :: keyword(boolean)) :: any
end
