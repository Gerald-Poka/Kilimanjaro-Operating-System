#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Gerald Ndyamukama
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# Reuses the last complete staging tree. This is only for boot-record changes;
# package, overlay, kernel or initramfs changes require the normal full repack.
bash "$SCRIPT_DIR/assemble-iso.sh"
bash "$SCRIPT_DIR/05-release.sh"
