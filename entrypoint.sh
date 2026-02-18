#!/usr/bin/env bash
##
# Entrypoint for the Docker container.
#
set -euo pipefail

echo "yourproject is running"

exec "$@"
