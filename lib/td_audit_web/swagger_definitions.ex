defmodule TdAuditWeb.SwaggerDefinitions do
  @moduledoc """
   Swagger definitions used by controllers
  """
  import PhoenixSwagger

  def event_swagger_definitions do
    %{
      Event: swagger_schema do
        title "Event"
        description "An Event"
        properties do
          id :integer, "Unique identifier", required: true
          event :string, "Event name", required: true
          payload :object, "Payload", required: true
          resource_id :integer, "Resource ID", required: true
          resource_type :string, "Resource type", required: true
          service :string, "Service audited", required: true
          ts :string, "Timestamps", required: true
          user_id :integer, "User ID", required: true
          user_name :string, "User name", required: true
        end
        example %{
          id: 12,
          event: "some event",
          payload: %{"example" => "payload"},
          resource_id: 100,
          resource_type: "some resource type",
          service: "some service",
          ts: "2018-05-08T17:17:59.691460",
          user_id: 1,
          user_name: "some user name"
        }
      end,
      EventCreate: swagger_schema do
        properties do
          event (Schema.new do
            properties do
              event :string, "Event name", required: true
              payload :object, "Payload", required: true
              resource_id :integer, "Resource ID", required: true
              resource_type :string, "Resource type", required: true
              service :string, "Service audited", required: true
              user_id :integer, "User ID", required: true
              user_name :string, "User name", required: true
             end
          end)
        end
      end,
      EventUpdate: swagger_schema do
        properties do
          event (Schema.new do
            properties do
              event :string, "Event name", required: true
              payload :object, "Payload", required: true
              resource_id :integer, "Resource ID", required: true
              resource_type :string, "Resource type", required: true
              service :string, "Service audited", required: true
              ts :string, "Timestamps"
              user_id :integer, "User ID", required: true
              user_name :string, "User name", required: true
            end
          end)
        end
      end,
      Events: swagger_schema do
        title "Events"
        description "A collection of Events"
        type :array
        items Schema.ref(:Event)
      end,
      EventResponse: swagger_schema do
        properties do
          data Schema.ref(:Event)
        end
      end,
      EventsResponse: swagger_schema do
        properties do
          data Schema.ref(:Events)
        end
      end,
    }
  end
end
