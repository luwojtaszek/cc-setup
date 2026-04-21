#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
echo "WARN: use ./install.sh; running full install" >&2
exec bash "$SCRIPT_DIR/install.sh" "$@"
