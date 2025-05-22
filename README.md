# Weather API

A Phoenix-based API service for fetching weather data from predefined or custom locations. This lightweight API does not use a database and focuses purely on serving weather data.

## Running the Application

Clone the repository and install dependencies:

```bash
git clone https://github.com/Xarlie-Xarlie/weather-api.git
cd weather_api
mix deps.get
```

Start the Phoenix server:

```bash
mix phx.server
```

The server will be accessible at http://localhost:4000.

## Running Tests

The project includes a comprehensive test suite. Run all tests with:

```bash
mix test
```

The tests use mocking to avoid real API calls, ensuring they run quickly and reliably.

## API Endpoints

The application exposes the following REST API endpoints:

### GET /api/weather

Fetches weather data for predefined locations (São Paulo, Belo Horizonte, and Curitiba).

**Example Request:**
```
GET http://localhost:4000/api/weather
```

**Example Response:**
```json
[
  {"São Paulo": "23.9°C"},
  {"Belo Horizonte": "22.5°C"},
  {"Curitiba": "18.6°C"}
]
```

### POST /api/weather/custom

Fetches weather data for custom locations specified in the request body.

**Request Body Format:**
```json
{
  "locations": [
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
}
```

**Example Request:**
```
POST http://localhost:4000/api/weather/custom
Content-Type: application/json

{
  "locations": [
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
}
```

**Example Response:**
```json
[
  {"New York": "20.0°C"},
  {"London": "15.0°C"}
]
```

## Mix Task

The application includes a Mix task for fetching weather data from the command line.

### Basic Usage

```
mix weather.fetch
```

This will fetch weather data for the predefined locations and output it as JSON.

### Options

- `--timeout=<milliseconds>`: Set a custom timeout (default: 10000)
- `--pretty`: Pretty-print the JSON output
- `--locations=<file_path>`: Path to a JSON file containing custom locations

### Custom Locations File Format

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

### Examples

```bash
# Fetch weather data with default options
mix weather.fetch

# Fetch weather data with a custom timeout (in milliseconds)
mix weather.fetch --timeout=15000

# Fetch weather data with custom locations from a JSON file
mix weather.fetch --locations=test/fixtures/locations.json

# Pretty-print the JSON output
mix weather.fetch --pretty
```

## Development

To check formatting:

```bash
mix format
```

To compile and check for warnings:

```bash
mix compile --warnings-as-errors
```

## License

[MIT License](LICENSE)
