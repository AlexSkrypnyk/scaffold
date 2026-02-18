#!/usr/bin/env bash
##
# Entrypoint for the Docker container.
#
set -euo pipefail

echo "force-crystal is running"

exec "$@"
