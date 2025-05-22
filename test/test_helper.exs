Mox.defmock(Weather.ClientMock, for: Weather.HttpClient)
Application.put_env(:weather, :client, Weather.ClientMock)

ExUnit.start()
