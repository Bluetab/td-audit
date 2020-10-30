defmodule TdAudit.K8s do
  @moduledoc """
  Module to connect to k8s cluster 
  """

  require Logger

  def run(implementations_by_engine) do
    Enum.map(implementations_by_engine, &create/1)
  end

  defp create({engine, implementations}) do
    {:ok, conn} = get_connection()

    engine
    |> get_cronjobs(conn)
    |> case do
      {:error, _} -> {:error, implementations}
      {:ok, []} -> {:unexecuted, implementations}
      {:ok, cronjobs} -> do_create(cronjobs, implementations, conn)
    end
  end

  defp do_create(cronjobs, implementations, conn) do
    job_template =
      cronjobs
      |> List.first()
      |> Map.get("spec")
      |> Map.get("jobTemplate")
      |> Map.get("spec")
      |> Map.put("ttlSecondsAfterFinished", 1)
      |> update_env_implementations(implementations)

    job = %{
      "apiVersion" => "batch/v1",
      "kind" => "Job",
      "metadata" => %{"name" => UUID.uuid1(), "namespace" => "default"},
      "spec" => job_template
    }

    job
    |> K8s.Client.create()
    |> K8s.Client.run(conn)
    |> case do
      {:error, response} ->
        response
        |> Map.get(:body)
        |> Logger.error()

        {:error, implementations}

      {:ok, _} ->
        {:ok, implementations}
    end
  end

  defp update_env_implementations(job_template, implementations) do
    template = Map.get(job_template, "template")
    spec = Map.get(template, "spec")
    containers = Map.get(spec, "containers")

    container =
      containers
      |> List.first()
      |> Map.put("env", [
        %{"name" => "TD_QUERY_IMPLEMENTATION", "value" => Enum.join(implementations, ",")}
      ])

    spec = Map.merge(spec, %{"containers" => List.replace_at(containers, 0, container)})
    template = Map.merge(template, %{"spec" => spec})
    Map.merge(job_template, %{"template" => template})
  end

  defp get_cronjobs(engine, conn) do
    "batch/v1beta1"
    |> K8s.Client.list("CronJob")
    |> K8s.Selector.label({"truedat/connector-type", "DQ"})
    |> K8s.Selector.label({"truedat/connector-engine", engine})
    |> K8s.Client.run(conn)
    |> case do
      {:error, error} ->
        {:error, error}

      {:ok, cronjobs} ->
        {:ok, Map.fetch!(cronjobs, "items")}
    end
  end

  defp get_connection do
    :k8s
    |> Application.get_env(:clusters)
    |> get_connection()
  end

  defp get_connection(%{default: default}) when default == %{} do
    K8s.Conn.from_service_account(:default)
  end

  defp get_connection(_) do
    K8s.Conn.lookup(:default)
  end
end
