defmodule Weather.HttpClient do
  @callback call(map()) :: {:ok, map()} | {:error, String.t()}
end
