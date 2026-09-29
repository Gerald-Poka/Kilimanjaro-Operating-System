#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

"$SCRIPT_DIR/00-host-check.sh"
"$SCRIPT_DIR/01-bootstrap.sh"
"$SCRIPT_DIR/02-packages.sh"
"$SCRIPT_DIR/03-configure.sh"
"$SCRIPT_DIR/04-image.sh"
"$SCRIPT_DIR/05-release.sh"

