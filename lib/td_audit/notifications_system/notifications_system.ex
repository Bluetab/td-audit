defmodule TdAudit.NotificationsSystem do
  @moduledoc """
  The NotificationsSystem context.
  """

  import Ecto.Query, warn: false
  alias TdAudit.NotificationsSystem.Configuration
  alias TdAudit.QuerySupport
  alias TdAudit.Repo
  alias TdAudit.Subscriptions

  @doc """
  Returns the list of notifications_system_configuration.

  ## Examples

      iex> list_notifications_system_configuration()
      [%Configuration{}, ...]

  """
  def list_notifications_system_configuration do
    Repo.all(Configuration)
  end

  @doc """
  Gets a single configuration.

  Raises `Ecto.NoResultsError` if the Configuration does not exist.

  ## Examples

      iex> get_configuration!(123)
      %Configuration{}

      iex> get_configuration!(456)
      ** (Ecto.NoResultsError)

  """
  def get_configuration!(id), do: Repo.get!(Configuration, id)

  @doc """
  Gets a single configuration given a set of params.

  Raises `Ecto.NoResultsError` if the Configuration does not exist.

  ## Examples

      iex> get_configuration!(123)
      %Configuration{}

      iex> get_configuration!(456)
      ** (Ecto.NoResultsError)

  """
  def get_configuration_by_filter(params) do
    fields = Configuration.__schema__(:fields)
    dynamic = QuerySupport.filter(params, fields)

    Repo.one(
      from(p in Configuration,
        where: ^dynamic
      )
    )
  end

  @doc """
  Creates a configuration.

  ## Examples

      iex> create_configuration(%{field: value})
      {:ok, %Configuration{}}

      iex> create_configuration(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_configuration(attrs \\ %{}) do
    response =
      %Configuration{}
      |> Configuration.changeset(attrs)
      |> Repo.insert()

    Subscriptions.update_last_consumed_events_on_activation(response)
    response
  end

  @doc """
  Updates a configuration.

  ## Examples

      iex> update_configuration(configuration, %{field: new_value})
      {:ok, %Configuration{}}

      iex> update_configuration(configuration, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_configuration(%Configuration{} = configuration, attrs) do
    response =
      configuration
      |> Configuration.changeset(attrs)
      |> Repo.update()

    Subscriptions.update_last_consumed_events_on_activation(response)
    response
  end

  @doc """
  Deletes a Configuration.

  ## Examples

      iex> delete_configuration(configuration)
      {:ok, %Configuration{}}

      iex> delete_configuration(configuration)
      {:error, %Ecto.Changeset{}}

  """
  def delete_configuration(%Configuration{} = configuration) do
    Repo.delete(configuration)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking configuration changes.

  ## Examples

      iex> change_configuration(configuration)
      %Ecto.Changeset{source: %Configuration{}}

  """
  def change_configuration(%Configuration{} = configuration) do
    Configuration.changeset(configuration, %{})
  end
end
