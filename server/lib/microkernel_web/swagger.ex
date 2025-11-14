defmodule MicrokernelWeb.Swagger do
  @moduledoc """
  OpenAPI/Swagger specification for Microkernel API
  """
  alias OpenApiSpex.{OpenApi, Info, PathItem, Operation, Response, Schema, Parameter, Components, SecurityScheme, Server}

  def spec do
    %OpenApi{
      openapi: "3.0.0",
      info: %Info{
        title: "Microkernel IoT Platform API",
        version: "0.1.0",
        description: """
        REST API for the Distributed IoT Microkernel Platform.
        
        This API provides endpoints for managing IoT devices, telemetry data,
        OTA updates, and alerts.
        
        ## Authentication
        
        All API endpoints require authentication using an API key.
        Include your API key in the `Authorization` header:
        
        ```
        Authorization: Bearer YOUR_API_KEY
        ```
        """
      },
      servers: [
        %Server{
          url: "http://localhost:4000",
          description: "Development server"
        }
      ],
      paths: %{
        "/api/devices" => %PathItem{
          get: %Operation{
            summary: "List devices",
            operationId: "list_devices",
            responses: %{
              "200" => %Response{
                description: "List of devices",
                content: %{
                  "application/json" => %{
                    schema: %Schema{
                      type: :array,
                      items: device_schema()
                    }
                  }
                }
              }
            },
            tags: ["Devices"]
          }
        },
        "/api/devices/{device_id}" => %PathItem{
          get: %Operation{
            summary: "Get device",
            operationId: "get_device",
            parameters: [
              %Parameter{
                name: :device_id,
                in: :path,
                required: true,
                schema: %Schema{type: :string}
              }
            ],
            responses: %{
              "200" => %Response{
                description: "Device details",
                content: %{
                  "application/json" => %{
                    schema: device_schema()
                  }
                }
              },
              "404" => %Response{description: "Device not found"}
            },
            tags: ["Devices"]
          }
        },
        "/api/devices/{device_id}/telemetry" => %PathItem{
          get: %Operation{
            summary: "Get telemetry readings",
            operationId: "get_telemetry",
            parameters: [
              %Parameter{
                name: :device_id,
                in: :path,
                required: true,
                schema: %Schema{type: :string}
              },
              %Parameter{
                name: :limit,
                in: :query,
                required: false,
                schema: %Schema{type: :integer, default: 100}
              },
              %Parameter{
                name: :since,
                in: :query,
                required: false,
                schema: %Schema{type: :string, format: :date_time}
              },
              %Parameter{
                name: :sensor_type,
                in: :query,
                required: false,
                schema: %Schema{type: :string}
              }
            ],
            responses: %{
              "200" => %Response{
                description: "Telemetry readings",
                content: %{
                  "application/json" => %{
                    schema: %Schema{
                      type: :array,
                      items: telemetry_reading_schema()
                    }
                  }
                }
              }
            },
            tags: ["Telemetry"]
          }
        },
        "/api/devices/{device_id}/telemetry/export" => %PathItem{
          get: %Operation{
            summary: "Export telemetry data",
            operationId: "export_telemetry",
            parameters: [
              %Parameter{
                name: :device_id,
                in: :path,
                required: true,
                schema: %Schema{type: :string}
              },
              %Parameter{
                name: :format,
                in: :query,
                required: false,
                schema: %Schema{type: :string, enum: ["csv", "json"], default: "csv"}
              }
            ],
            responses: %{
              "200" => %Response{
                description: "Exported data",
                content: %{
                  "text/csv" => %{},
                  "application/json" => %{}
                }
              }
            },
            tags: ["Telemetry"]
          }
        }
      },
      components: %Components{
        securitySchemes: %{
          "ApiKeyAuth" => %SecurityScheme{
            type: "http",
            scheme: "bearer",
            bearerFormat: "API Key"
          }
        }
      },
      security: [
        %{"ApiKeyAuth" => []}
      ]
    }
  end

  defp device_schema do
    %Schema{
      type: :object,
      properties: %{
        device_id: %Schema{type: :string},
        name: %Schema{type: :string},
        status: %Schema{type: :string, enum: ["online", "offline", "unknown"]},
        firmware_version: %Schema{type: :string},
        last_seen: %Schema{type: :string, format: :date_time}
      }
    }
  end

  defp telemetry_reading_schema do
    %Schema{
      type: :object,
      properties: %{
        device_id: %Schema{type: :string},
        sensor_type: %Schema{type: :string},
        value: %Schema{type: :number},
        unit: %Schema{type: :string},
        anomaly: %Schema{type: :boolean},
        confidence: %Schema{type: :number},
        timestamp: %Schema{type: :string, format: :date_time}
      }
    }
  end
end

