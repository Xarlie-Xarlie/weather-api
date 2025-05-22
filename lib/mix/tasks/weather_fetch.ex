defmodule Mix.Tasks.Weather.Fetch do
  @moduledoc """
  Fetches weather data from predefined locations.

  ## Examples

      # Fetch weather data with default options
      mix weather.fetch

      # Fetch weather data with a custom timeout (in milliseconds)
      mix weather.fetch --timeout=15000

  ## Command line options

    * `--timeout` - Sets the timeout in milliseconds (default: 10000)
    * `--pretty` - Pretty-prints the JSON output (default: false)

  """

  use Mix.Task
  require Logger

  @shortdoc "Fetches weather data"

  @impl Mix.Task
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        strict: [timeout: :integer, pretty: :boolean]
      )

    Mix.Task.run("app.start")

    timeout = Keyword.get(opts, :timeout, 10_000)
    Logger.info("Fetching weather data with timeout: #{timeout}ms")

    case Weather.call(timeout: timeout) do
      {:ok, results} ->
        json = Jason.encode!(results, pretty: Keyword.get(opts, :pretty, false))
        IO.puts(json)

      {:error, reason} ->
        Mix.raise("Error fetching weather data: #{inspect(reason)}")
    end
  end
end
