defmodule Mix.Tasks.Weather.Fetch do
  @moduledoc """
  Fetches weather data from predefined locations or custom locations.

  ## Examples

      # Fetch weather data with default options
      mix weather.fetch

      # Fetch weather data with a custom timeout (in milliseconds)
      mix weather.fetch --timeout=15000

      # Fetch weather data with custom locations from a JSON file
      mix weather.fetch --locations=locations.json

      # Fetch weather data with custom locations from a JSON file and a custom timeout
      mix weather.fetch --locations=locations.json --timeout=15000

      # Pretty-print the JSON output
      mix weather.fetch --pretty

  ## Command line options

    * `--timeout` - Sets the timeout in milliseconds (default: 10000)
    * `--pretty` - Pretty-prints the JSON output (default: false)
    * `--locations` - Path to a JSON file containing custom locations (default: nil)

  ## JSON file format for custom locations

  The locations JSON file should contain an array of objects, each with the following properties:
  ```json
  [
    {
      "location": "New York",
      "latitude": 40.71,
      "longitude": -74.01
    },
    {
      "location": "London",
      "latitude": 51.51,
      "longitude": -0.13
    }
  ]
  ```
  """

  use Mix.Task
  require Logger

  @shortdoc "Fetches weather data"

  @impl Mix.Task
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        strict: [timeout: :integer, pretty: :boolean, locations: :string]
      )

    Mix.Task.run("app.start")

    timeout = Keyword.get(opts, :timeout, 10_000)
    pretty = Keyword.get(opts, :pretty, false)
    locations_file = Keyword.get(opts, :locations)

    weather_opts = [timeout: timeout]

    weather_opts =
      case locations_file do
        nil ->
          Logger.info("Fetching weather data for predefined locations with timeout: #{timeout}ms")
          weather_opts

        file ->
          case read_locations_file(file) do
            {:ok, locations} ->
              Logger.info(
                "Fetching weather data for #{length(locations)} custom locations with timeout: #{timeout}ms"
              )

              Keyword.put(weather_opts, :locations, locations)

            {:error, reason} ->
              Mix.raise("Error reading locations file: #{reason}")
          end
      end

    case Weather.call(weather_opts) do
      {:ok, results} ->
        json = Jason.encode!(results, pretty: pretty)
        IO.puts(json)

      {:error, reason} ->
        Mix.raise("Error fetching weather data: #{inspect(reason)}")
    end
  end

  @doc """
  Reads and parses a JSON file containing location data.

  ## Parameters
    - `file_path`: Path to the JSON file.

  ## Returns
    - `{:ok, locations}`: A list of parsed location maps.
    - `{:error, reason}`: If the file cannot be read or parsed.
  """
  def read_locations_file(file_path) do
    with {:ok, content} <- File.read(file_path),
         {:ok, json} <- Jason.decode(content),
         {:ok, locations} <- validate_locations(json) do
      {:ok, locations}
    else
      {:error, %Jason.DecodeError{}} ->
        {:error, "Invalid JSON format in locations file"}

      {:error, reason} when is_binary(reason) ->
        {:error, reason}

      {:error, reason} ->
        {:error, inspect(reason)}
    end
  end

  @doc """
  Validates the location data from a JSON file.

  ## Parameters
    - `locations`: A list of location maps from the JSON file.

  ## Returns
    - `{:ok, validated_locations}`: A list of validated location maps.
    - `{:error, reason}`: If the locations data is invalid.
  """
  def validate_locations(locations) when is_list(locations) do
    validation_results = Enum.map(locations, &validate_location/1)

    case Enum.find(validation_results, &(elem(&1, 0) == :error)) do
      nil ->
        valid_locations = Enum.map(validation_results, fn {:ok, location} -> location end)
        {:ok, valid_locations}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def validate_locations(_), do: {:error, "Locations must be an array"}

  defp validate_location(%{
         "location" => location,
         "latitude" => latitude,
         "longitude" => longitude
       })
       when is_binary(location) and (is_float(latitude) or is_integer(latitude)) and
              (is_float(longitude) or is_integer(longitude)) do
    {:ok,
     %{
       location: location,
       latitude: latitude,
       longitude: longitude
     }}
  end

  defp validate_location(_),
    do:
      {:error,
       "Each location must have 'location' (string), 'latitude' (number), and 'longitude' (number)"}
end
