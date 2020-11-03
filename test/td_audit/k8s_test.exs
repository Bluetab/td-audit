defmodule TdAudit.K8sTest do
  use TdAudit.DataCase

  alias K8s.Client.DynamicHTTPProvider
  alias TdAudit.K8s, as: HelperK8s
  alias TdAudit.K8sMock

  setup_all do
    start_supervised(DynamicHTTPProvider)
    :ok
  end

  setup do
    DynamicHTTPProvider.register(self(), K8sMock)
  end

  test "Create and run job" do
    results = HelperK8s.run(%{"Glue-Athena" => ["ri0002", "ri0003"], "Empty" => ["ri0001"]})
    assert results == [{:unexecuted, ["ri0001"]}, {:ok, ["ri0002", "ri0003"]}]
  end
end
