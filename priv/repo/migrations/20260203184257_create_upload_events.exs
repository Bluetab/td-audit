defmodule TdAudit.Repo.Migrations.CreateUploadJobs do
  use Ecto.Migration

  def change do
    create table("upload_jobs") do
      add(:user_id, :bigint)
      add(:hash, :string)
      add(:filename, :string)
      add(:scope, :string)

      timestamps(updated_at: false, type: :utc_datetime_usec)
    end

    create table("upload_events") do
      add(:job_id, references("upload_jobs"))
      add(:response, :map)
      add(:status, :string)

      timestamps(updated_at: false, type: :utc_datetime_usec)
    end
  end
end
