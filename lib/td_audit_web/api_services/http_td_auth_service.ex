defmodule TdAuditWeb.ApiServices.HttpTdAuthService do
  @moduledoc false

  alias Jason, as: JSON
  alias TdAudit.Accounts.User

  defp get_config do
    Application.get_env(:td_audit, :auth_service)
  end

  defp get_api_user_token do
    api_config = Application.get_env(:td_audit, :api_services_login)

    user_credentials = %{
      user_name: api_config[:api_username],
      password: api_config[:api_password]
    }

    body = %{user: user_credentials} |> JSON.encode!()

    %HTTPoison.Response{status_code: _status_code, body: resp} =
      HTTPoison.post!(
        get_sessions_path(),
        body,
        ["Content-Type": "application/json", Accept: "Application/json; Charset=utf-8"],
        []
      )

    resp = resp |> JSON.decode!()
    resp["token"]
  end

  defp get_auth_endpoint do
    auth_service_config = get_config()

    "#{auth_service_config[:protocol]}://#{auth_service_config[:auth_host]}:#{
      auth_service_config[:auth_port]
    }"
  end

  defp get_users_path do
    auth_service_config = get_config()
    "#{get_auth_endpoint()}#{auth_service_config[:users_path]}"
  end

  defp get_sessions_path do
    auth_service_config = get_config()
    "#{get_auth_endpoint()}#{auth_service_config[:sessions_path]}"
  end

  def search(%{"ids" => _ids} = ids) do
    token = get_api_user_token()

    headers = [
      Authorization: "Bearer #{token}",
      "Content-Type": "application/json",
      Accept: "Application/json; Charset=utf-8"
    ]

    req = %{"data" => ids}
    body = req |> JSON.encode!()

    %HTTPoison.Response{status_code: _status_code, body: resp} =
      HTTPoison.post!("#{get_users_path()}/search", body, headers, [])

    json =
      resp
      |> JSON.decode!()

    json = json["data"]
    users = Enum.map(json, fn user -> %User{} |> Map.merge(to_struct(User, user)) end)
    users
  end

  def to_struct(kind, attrs) do
    struct = struct(kind)

    Enum.reduce(Map.to_list(struct), struct, fn {k, _}, acc ->
      case Map.fetch(attrs, Atom.to_string(k)) do
        {:ok, v} -> %{acc | k => v}
        :error -> acc
      end
    end)
  end
end
