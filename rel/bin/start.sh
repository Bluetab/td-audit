#!/bin/sh

set -o errexit
set -o xtrace

if [ ! -z ${TZDATA_DATA_DIR} ]; then
  mkdir -p ${TZDATA_DATA_DIR} &&
  cp -r /app/lib/tzdata*/priv/release_ets ${TZDATA_DATA_DIR} &&
  chown -R app: ${TZDATA_DATA_DIR} ;
fi

bin/td_audit eval 'Elixir.TdAudit.Release.migrate()'
bin/td_audit start
