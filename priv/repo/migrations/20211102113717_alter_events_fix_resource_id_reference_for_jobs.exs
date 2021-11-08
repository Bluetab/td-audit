defmodule TdAudit.Repo.Migrations.AlterEventsFixResourceIdReferenceForJobs do
  use Ecto.Migration

  import Ecto.Query
  
  alias TdAudit.Repo

  def up do
    execute(
      """
        update events set
        payload = events.payload || jsonb_build_object('source_id', events.resource_id),
        resource_id = cast(events.payload ->> 'job_id' as integer)
        where events.resource_type = 'jobs'
      """
    )
    execute(
      """
        update events
        set payload = events.payload - 'job_id'
        where events.resource_type = 'jobs'
      """
    )
  end

  def down do
    execute(
      """
        update events set
        payload = events.payload || jsonb_build_object('job_id', events.resource_id),
        resource_id = cast(events.payload ->> 'source_id' as integer)
        where events.resource_type = 'jobs'
      """
    )
    execute(
      """
        update events
        set payload = events.payload - 'source_id'
        where events.resource_type = 'jobs'
      """
    )
  end
end