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
      end
    }
  end

  def subscription_swagger_definitions do
    %{
      SubscriptionsResponse: swagger_schema do
        properties do
          data Schema.ref(:Subscriptions)
        end
      end,
      Subscriptions: swagger_schema do
        title "Subscriptions"
        description "A collection of subscriptions"
        type :array
        items Schema.ref(:Subscription)
      end,
      Subscription: swagger_schema do
        title "Subscription"
        description "A subscription of an user to a notification"
        properties do
          id :integer, "Unique identifier"
          event :string, "Event to subscribe"
          resource_id :integer, "ID of the resource triggering the event"
          resource_type :string, "Type of the resource triggering the event"
          user_email :string, "Email of the subscriptor"
          periodicity :string, "Periodicity of the subscription"
          last_consumed_event :string, "Timestamps"
        end
      end,
      SubscriptionCreate: swagger_schema do
        properties do
          subscription (Schema.new do
            properties do
              id :integer, "Unique identifier", required: true
              event :string, "Event to subscribe", required: true
              resource_id :integer, "ID of the resource triggering the event", required: true
              resource_type :string, "Type of the resource triggering the event", required: true
              user_email :string, "Email of the subscriptor", required: true
              periodicity :string, "Periodicity of the subscription"
            end
          end)
        end
      end,
      SubscriptionResponse: swagger_schema do
        properties do
          data Schema.ref(:Subscription)
        end
      end,
      SubscriptionUpdate: swagger_schema do
        properties do
          subscription (Schema.new do
            properties do
              event :string, "Event to subscribe", required: true
              resource_id :integer, "ID of the resource triggering the event", required: true
              resource_type :string, "Type of the resource triggering the event", required: true
              user_email :string, "Email of the subscriptor", required: true
              periodicity :string, "Periodicity of the subscription"
            end
          end)
      end
    end
    }
  end

  def configuration_swagger_definitions do
    %{
      ConfigurationsResponse: swagger_schema do
        properties do
          data Schema.ref(:Configurations)
        end
      end,
      Configurations: swagger_schema do
        title "Configurations"
        description "A collection of configurations"
        type :array
        items Schema.ref(:Configuration)
      end,
      Configuration: swagger_schema do
        title "Configuration"
        description "A configuration for our notifications system"
        properties do
          id :integer, "Unique identifier"
          event :string, "Event to generate a configuration"
          settings :object, "Specifics of the configuration"
        end

        example(
        %{
          configuration:
            %{
              event: "create_concept_draft",
              settings: %{
                "generate_subscription": %{
                  "roles": ["data_owner"]
                },
                "generate_notification": %{
                  "active": false
                }
              }
            }
          }
        )

      end,
      ConfigurationCreate: swagger_schema do
        properties do
          configuration (Schema.new do
            properties do
              event :string, "Event to create a configuration", required: true
              settings :object, "Specifics of the configuration", required: true
            end
          end)
        end

        example(
        %{
          configuration:
            %{
              event: "create_concept_draft",
              settings: %{
                "generate_subscription": %{
                  "roles": ["data_owner"]
                },
                "generate_notification": %{
                  "active": false
                }
              }
            }
        })
      end,
      ConfigurationResponse: swagger_schema do
        properties do
          data Schema.ref(:Configuration)
        end
      end,
      ConfigurationUpdate: swagger_schema do
        properties do
          configuration (Schema.new do
            properties do
              event :string, "Event to create a configuration", required: true
              settings :object, "Specifics of the configuration", required: true
            end
          end)
      end

      example(
      %{
        configuration:
        %{
          event: "create_concept_draft",
          settings: %{
            "generate_subscription": %{
              "roles": ["data_officer"]
            }
          }
        }
      })
    end
    }
  end
end
