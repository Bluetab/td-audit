#!/bin/sh

set -o errexit
set -o xtrace

bin/td_audit eval 'Elixir.TdAudit.Release.migrate()'
bin/td_audit start
