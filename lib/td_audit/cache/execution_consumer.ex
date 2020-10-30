defmodule TdAudit.Cache.ExecutionConsumer do
  @moduledoc """
  Module to dispatch actions when domain-related events are received.
  """

  @behaviour TdCache.EventStream.Consumer

  use GenServer

  alias Jason
  alias TdAudit.K8s, as: HelperK8s
  alias TdCache.SourceCache

  require Logger

  ## Client API

  def start_link(config \\ []) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  ## EventStream.Consumer Callbacks

  @impl true
  def consume(events) do
    GenServer.cast(__MODULE__, {:consume, events})
  end

  ## GenServer callbacks

  @impl true
  def init(state) do
    name = String.replace_prefix("#{__MODULE__}", "Elixir.", "")
    Logger.info("Running #{name}")

    {:ok, state}
  end

  @impl true
  def handle_cast({:consume, events}, state) do
    implementations = read_implementations(events)

    {:ok, sources} = SourceCache.sources()

    sources =
      sources
      |> Enum.map(&SourceCache.get/1)
      |> Enum.map(&do_read_sources/1)
      |> Enum.filter(&by_alias/1)
      |> Enum.map(&group_by_alias/1)
      |> Enum.into(%{})

    implementation_by_engine =
      implementations
      |> Enum.map(&put_engines(&1, sources))
      |> Enum.group_by(&Map.get(&1, "engine"), &Map.get(&1, "implementation_key"))

    HelperK8s.run(implementation_by_engine)
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Enum.map(&read_results/1)
    |> Enum.each(&log/1)

    {:noreply, state}
  end

  defp log(response) do
    case response do
      {:ok, ids} -> Logger.info("Executed implementations #{Jason.encode!(ids)}")
      {:unexecuted, ids} -> Logger.warn("Not executed implementations #{Jason.encode!(ids)}")
      {:error, ids} -> Logger.error("Error implementations #{Jason.encode!(ids)}")
      _ -> Logger.error("Unexpected response")
    end
  end

  defp read_results(result) do
    implementations =
    result
    |> elem(1)
    |> List.flatten()

    {elem(result, 0), implementations}
  end

  defp put_engines(%{"structure_aliases" => structure_aliases} = implementation, sources) do
    engine =
      sources
      |> Map.take(structure_aliases)
      |> Map.values()
      |> List.first()

    Map.put(implementation, "engine", engine)
  end

  defp group_by_alias(%{config: config, type: type}) do
    {_k, source_alias} = Enum.find(config, fn {key, _} -> String.contains?(key, "alias") end)
    {source_alias, type}
  end

  defp by_alias(%{config: config}) do
    config
    |> Map.keys()
    |> Enum.any?(&String.contains?(&1, "alias"))
  end

  defp do_read_sources(source) do
    case source do
      {:ok, %{config: config, external_id: external_id, type: type}} ->
        Map.put(%{external_id: external_id, config: config}, :type, type)

      _ ->
        Logger.warn("Invalid format #{source}")
        %{}
    end
  end

  defp read_implementations(events) do
    events
    |> Enum.flat_map(&read_implementation/1)
  end

  defp read_implementation(%{event: "execute_implementations", payload: payload}) do
    payload
    |> Jason.decode!()
  end

  defp read_implementation(_), do: []
end
