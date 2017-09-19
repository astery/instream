use Mix.Config

alias Instream.TestHelpers


config :logger, :console,
  format: "\n$time $metadata[$level] $levelpad$message\n",
  metadata: [:query_time, :response_status]


connections =
  File.ls!("test/helpers/connections")
  |> Enum.filter( &String.contains?(&1, "connection") )
  |> Enum.map(fn (helper) ->
       conn =
         helper
         |> String.replace(".ex", "")
         |> String.replace("udp", "UDP") # adjust camelize behaviour
         |> Macro.camelize()

       Module.concat([ TestHelpers.Connections, conn ])
     end)


# setup global configuration defaults
Enum.each(connections, fn (connection) ->
  config :instream, connection,
    host: "localhost",
    pool: [ max_overflow: 0, size: 1 ]
end)

# setup authentication defaults
connections
|> Enum.reject(&( &1 == TestHelpers.Connections.AnonConnection ))
|> Enum.each(fn (connection) ->
     config :instream, connection,
       auth: [ username: "instream_test", password: "instream_test" ]
   end)

# setup logging defaults
connections
|> Enum.reject(&( &1 == TestHelpers.Connections.LogConnection ))
|> Enum.each(fn (connection) ->
     config :instream, connection,
       loggers: [{TestHelpers.NilLogger, :log, [] }]
   end)


# connection specific configuration
config :instream, TestHelpers.Connections.EnvConnection,
  auth:    [ username: { :system, "INSTREAM_TEST_ENV_USERNAME" },
             password: { :system, "INSTREAM_TEST_ENV_PASSWORD" } ],
  host:    { :system, "INSTREAM_TEST_ENV_HOST" }

config :instream, TestHelpers.Connections.GuestConnection,
  auth: [ username: "instream_guest", password: "instream_guest" ]

config :instream, TestHelpers.Connections.InetsConnection,
  # port will be set properly during test setup
  port: 99999

config :instream, TestHelpers.Connections.InvalidConnection,
  auth: [ username: "instream_test", password: "instream_invalid" ]

config :instream, TestHelpers.Connections.InvalidDbConnection,
  database: "invalid_test_database"

config :instream, TestHelpers.Connections.NotFoundConnection,
  auth: [ username: "instream_not_found", password: "instream_not_found" ]

config :instream, TestHelpers.Connections.OptionsConnection,
  http_opts: [ proxy: "http://invalidproxy" ]

config :instream, TestHelpers.Connections.QueryAuthConnection,
  auth: [ method: :query, username: "instream_test", password: "instream_test" ]

config :instream, TestHelpers.Connections.UDPConnection,
  port_udp: 8089,
  writer:   Instream.Writer.UDP

config :instream, TestHelpers.Connections.UnreachableConnection,
  host: "some.really.unreachable.host"
