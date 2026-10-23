#!/bin/sh
#
# Cleans up any previous run, brings the database up, and follows its log until you press
# Ctrl-C, which tears the stack back down again. Both ends use `down -v`.
#
# The data directory is not mounted, so it lives in the container's anonymous volume, which
# `down -v` removes. Every run therefore starts from an empty cluster, and the image's entrypoint
# runs ./docker-entrypoint-initdb.d in name order -- 00-create-database-demo.sql, then the fetched
# demo-*.sql.gz -- before it accepts connections from outside. The dump is about 1.3 GB once
# loaded, so that takes a few minutes; the healthcheck in compose.yaml waits for it.
#
# The dump is not in git. ./_fetch-demo.sh is run first and downloads it if it is not here yet.
#
set -eu

cd "$(dirname "$0")"

if docker compose version >/dev/null 2>&1; then
    compose() { docker compose "$@"; }
else
    compose() { docker-compose "$@"; }
fi

logs_pid=""

on_interrupt() {
    # stop trapping, so a second Ctrl-C can still kill a slow teardown
    trap - INT TERM
    # guard, not `&&`: under `set -e` an empty logs_pid (Ctrl-C during startup, before the
    # log tail exists) would make the handler exit before it ever ran `down -v`
    if [ -n "${logs_pid}" ]; then
        kill "${logs_pid}" 2>/dev/null || true
    fi
    echo
    echo "==> down -v ..."
    compose down -v
    exit 0
}

trap on_interrupt INT TERM

# clear out whatever a previous run left behind -- a container killed without the trap
# firing would otherwise be reused by `up -d`
echo "==> down -v (cleaning up any previous run) ..."
compose down -v

./_fetch-demo.sh

echo "==> up -d ..."
compose up -d

echo "==> following the log; Ctrl-C to bring it down"
echo
# `logs -f` runs in the background and the script waits on it: a foreground child would
# make the shell defer the trap until it exited, and `logs -f` never exits on its own.
compose logs -f &
logs_pid=$!
wait "${logs_pid}"
