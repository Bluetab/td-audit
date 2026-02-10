defmodule TdCluster.ClusterTdAuditUploadJobsTest do
  use TdAudit.DataCase

  alias TdCluster.Cluster.TdAudit.UploadJobs

  # @moduletag sandbox: :shared

  describe "create_job/1" do
    test "with valid data creates a job" do
      assert {:ok, %TdAudit.UploadJobs.UploadJob{}} =
               UploadJobs.create_job(%{
                 user_id: 1,
                 hash: "hash",
                 filename: "filename",
                 scope: "implementations"
               })

    end

    test "with invalid data returns error" do
      assert {:error, %Ecto.Changeset{}} =
               UploadJobs.create_job(%{user_id: nil, hash: nil, filename: nil})
    end
  end

  describe "create_pending/1" do
    test "with valid data creates a job" do
      %{id: job_id} = insert(:upload_job)
      assert {:ok, %{job_id: ^job_id, status: "PENDING"}} = UploadJobs.create_pending(job_id)
    end

    test "with invalid data returns error" do
      assert {:error, %Ecto.Changeset{}} = UploadJobs.create_pending(nil)
    end
  end

  describe "create_error/2" do
    test "with valid data creates a job" do
      %{id: job_id} = insert(:upload_job)

      assert {:ok, %{job_id: ^job_id, status: "ERROR"}} =
               UploadJobs.create_error(job_id, %{error: "error"})
    end

    test "with invalid data returns error" do
      assert {:error, %Ecto.Changeset{}} = UploadJobs.create_error(nil, %{error: "error"})
    end
  end

  describe "create_info/2" do
    test "with valid data creates a job" do
      %{id: job_id} = insert(:upload_job)

      assert {:ok, %{job_id: ^job_id, status: "INFO"}} =
               UploadJobs.create_info(job_id, %{info: "info"})
    end

    test "with invalid data returns error" do
      assert {:error, %Ecto.Changeset{}} = UploadJobs.create_info(nil, %{info: "info"})
    end
  end

  describe "create_failed/2" do
    test "with valid data creates a job" do
      %{id: job_id} = insert(:upload_job)

      assert {:ok, %{job_id: ^job_id, status: "FAILED"}} =
               UploadJobs.create_failed(job_id, %{failed: "failed"})
    end

    test "with invalid data returns error" do
      assert {:error, %Ecto.Changeset{}} = UploadJobs.create_failed(nil, %{failed: "failed"})
    end
  end

  describe "create_started/1" do
    test "with valid data creates a job" do
      %{id: job_id} = insert(:upload_job)

      assert {:ok, %{job_id: ^job_id, status: "STARTED"}} =
               UploadJobs.create_started(job_id)
    end

    test "with invalid data returns error" do
      assert {:error, %Ecto.Changeset{}} = UploadJobs.create_started(nil)
    end
  end

  describe "create_completed/2" do
    test "with valid data creates a job" do
      %{id: job_id} = insert(:upload_job)

      assert {:ok, %{job_id: ^job_id, status: "COMPLETED"}} =
               UploadJobs.create_completed(job_id, %{completed: "completed"})
    end

    test "with invalid data returns error" do
      assert {:error, %Ecto.Changeset{}} =
               UploadJobs.create_completed(nil, %{completed: "completed"})
    end
  end
end
