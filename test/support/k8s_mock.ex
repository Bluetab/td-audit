defmodule TdAudit.K8sMock do
  @moduledoc """
  This module defines the functions required to
  add auth headers to requests
  """

  @base_url "https://localhost:6443"

  def request(:get, @base_url <> "/apis/batch/v1beta1/cronjobs", _, _,
        ssl: _ssl,
        params: %{labelSelector: "truedat/connector-engine=Glue-Athena,truedat/connector-type=DQ"}
      ) do
    cronjobs = %{
      "apiVersion" => "batch/v1beta1",
      "items" => [
        %{
          "metadata" => %{
            "labels" => %{
              "truedat/connector-engine" => "Glue-Athena",
              "truedat/connector-type" => "DQ"
            }
          },
          "spec" => %{
            "jobTemplate" => %{
              "metadata" => %{},
              "spec" => %{
                "backoffLimit" => 0,
                "template" => %{
                  "metadata" => %{},
                  "spec" => %{
                    "containers" => [
                      %{
                        "envFrom" => [],
                        "image" => ""
                      }
                    ]
                  }
                }
              }
            }
          }
        }
      ],
      "kind" => "CronJobList",
      "metadata" => %{
        "resourceVersion" => "1070156",
        "selfLink" => "/apis/batch/v1beta1/cronjobs"
      }
    }

    body = Jason.encode!(cronjobs)
    {:ok, %HTTPoison.Response{status_code: 200, body: body}}
  end

  def request(:get, @base_url <> "/apis/batch/v1beta1/cronjobs", _, _,
        ssl: _ssl,
        params: %{labelSelector: "truedat/connector-engine=Empty,truedat/connector-type=DQ"}
      ) do
    cronjobs = %{
      "apiVersion" => "batch/v1beta1",
      "items" => [],
      "kind" => "CronJobList",
      "metadata" => %{
        "resourceVersion" => "1070156",
        "selfLink" => "/apis/batch/v1beta1/cronjobs"
      }
    }

    body = Jason.encode!(cronjobs)
    {:ok, %HTTPoison.Response{status_code: 200, body: body}}
  end

  def request(:post, @base_url <> "/apis/batch/v1/namespaces/default/jobs", _, _, _) do
    job = %{}
    body = Jason.encode!(job)
    {:ok, %HTTPoison.Response{status_code: 200, body: body}}
  end
end
