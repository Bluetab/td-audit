defmodule TdAudit.Scheduler do
  @moduledoc "A Quantum scheduler for launching periodic tasks"

  use Quantum, otp_app: :td_audit
end
