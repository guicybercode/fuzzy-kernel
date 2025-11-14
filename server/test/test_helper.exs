ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(Microkernel.Repo, :manual)

Mox.defmock(Microkernel.MQTT.MockClient, for: Microkernel.MQTT.ClientBehaviour)

