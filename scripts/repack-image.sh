#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

"$SCRIPT_DIR/03-configure.sh"
"$SCRIPT_DIR/04-image.sh"
"$SCRIPT_DIR/05-release.sh"
