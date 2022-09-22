#!/bin/sh

# Run as root

set -o errexit
set -o xtrace

if [ ! -z "${TZDATA_DATA_DIR}" ]; then
  mkdir -p "${TZDATA_DATA_DIR}" &&
  cp -r /app/lib/tzdata*/priv/release_ets "${TZDATA_DATA_DIR}" &&
  chown -R app: "${TZDATA_DATA_DIR}" ;
else
  echo "Warning: TZDATA_DATA_DIR not set. :tzdata_release_updater will fail if /app/lib/tzdata-<VERSION>/priv/ is inside a read-only filesystem"
fi

# Run as app user

su-exec app bin/td_audit eval 'Elixir.TdAudit.Release.migrate()'
su-exec app bin/td_audit start
