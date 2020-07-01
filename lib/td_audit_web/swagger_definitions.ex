defmodule TdAuditWeb.SwaggerDefinitions do
  @moduledoc """
  Swagger definitions used by controllers
  """

  import PhoenixSwagger

  def event_swagger_definitions do
    %{
      Event:
        swagger_schema do
          title("Event")
          description("An Event")

          properties do
            id(:integer, "Unique identifier", required: true)
            event(:string, "Event name", required: true)
            payload(:object, "Payload", required: true)
            resource_id(:integer, "Resource ID", required: true)
            resource_type(:string, "Resource type", required: true)
            service(:string, "Service audited", required: true)
            ts(:string, "Timestamps", required: true)
            user_id(:integer, "User ID", required: true)
            user_name(:string, "User Name")
            user(:object, "User")
          end

          example(%{
            id: 12,
            event: "some event",
            payload: %{"example" => "payload"},
            resource_id: 100,
            resource_type: "some resource type",
            service: "some service",
            ts: "2018-05-08T17:17:59.691000",
            user_id: 1,
            user_name: "user1234",
            user: %{"id" => 1234, "user_name" => "user1234", "full_name" => "User 1234"}
          })
        end,
      Events:
        swagger_schema do
          title("Events")
          description("A collection of Events")
          type(:array)
          items(Schema.ref(:Event))
        end,
      EventResponse:
        swagger_schema do
          properties do
            data(Schema.ref(:Event))
          end
        end,
      EventsResponse:
        swagger_schema do
          properties do
            data(Schema.ref(:Events))
          end
        end
    }
  end

  def subscriber_swagger_definitions do
    %{
      SubscribersResponse:
        swagger_schema do
          properties do
            data(Schema.ref(:Subscribers))
          end
        end,
      Subscribers:
        swagger_schema do
          title("Subscribers")
          description("A collection of subscribers")
          type(:array)
          items(Schema.ref(:Subscriber))
        end,
      Subscriber:
        swagger_schema do
          title("Subscriber")
          description("A subscriber")

          properties do
            id(:integer, "Subscriber ID")
            type(:string, "Subscriber type (email, user or role)")
            identifier(:string, "Identifier of the subscriber")
          end
        end,
      SubscriberCreate:
        swagger_schema do
          properties do
            subscriber(
              Schema.new do
                properties do
                  type(:string, "Subscriber type (email, user or role)", required: true)
                  identifier(:string, "Identifier of the subscriber", required: true)
                end
              end
            )
          end
        end,
      SubscriberResponse:
        swagger_schema do
          properties do
            data(Schema.ref(:Subscriber))
          end
        end
    }
  end

  def subscription_swagger_definitions do
    %{
      SubscriptionsResponse:
        swagger_schema do
          properties do
            data(Schema.ref(:Subscriptions))
          end
        end,
      Subscriptions:
        swagger_schema do
          title("Subscriptions")
          description("A collection of subscriptions")
          type(:array)
          items(Schema.ref(:Subscription))
        end,
      Subscriber:
        swagger_schema do
          title("Subscriber")
          description("A subscriber")

          properties do
            type(:string, "Subscriber type (email, user or role)")
            identifier(:string, "Identifier of the subscriber")
          end
        end,
      Subscription:
        swagger_schema do
          title("Subscription")
          description("A subscription of an user to a notification")

          properties do
            id(:integer, "Unique identifier")
            event(:string, "Event to subscribe")
            resource_id(:integer, "ID of the resource triggering the event")
            resource_type(:string, "Type of the resource triggering the event")
            subscriber(Schema.ref(:Subscriber))
            periodicity(:string, "Periodicity of the subscription")
            last_event_id(:integer, "ID of last seen event")
          end
        end,
      SubscriptionCreate:
        swagger_schema do
          properties do
            subscription(
              Schema.new do
                properties do
                  id(:integer, "Unique identifier", required: true)
                  event(:string, "Event to subscribe", required: true)
                  resource_id(:integer, "ID of the resource triggering the event", required: true)

                  resource_type(:string, "Type of the resource triggering the event",
                    required: true
                  )

                  user_email(:string, "Email of the subscriber", required: true)
                  periodicity(:string, "Periodicity of the subscription")
                end
              end
            )
          end
        end,
      SubscriptionResponse:
        swagger_schema do
          properties do
            data(Schema.ref(:Subscription))
          end
        end,
      SubscriptionsUpdate:
        swagger_schema do
          properties do
            subscriptions(
              Schema.new do
                properties do
                  event(:string, "Event to subscribe", required: true)

                  resource_type(:string, "Type of the resource triggering the event",
                    required: true
                  )

                  role(:string, "Role of the subscribers", required: true)
                  periodicity(:string, "Periodicity of the subscription", required: true)
                end
              end
            )
          end
        end,
      SubscriptionUpdate:
        swagger_schema do
          properties do
            subscription(
              Schema.new do
                properties do
                  event(:string, "Event to subscribe", required: true)
                  resource_id(:integer, "ID of the resource triggering the event", required: true)

                  resource_type(:string, "Type of the resource triggering the event",
                    required: true
                  )

                  user_email(:string, "Email of the subscriber", required: true)
                  periodicity(:string, "Periodicity of the subscription")
                end
              end
            )
          end
        end
    }
  end
end
