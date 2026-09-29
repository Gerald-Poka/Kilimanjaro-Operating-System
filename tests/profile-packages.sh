#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=../config/build.env
source "$ROOT_DIR/config/build.env"

if [[ ! -f /.dockerenv && ! -f /run/.containerenv ]]; then
  printf 'FAIL: profile package validation must run in the disposable builder container.\n' >&2
  exit 1
fi

[[ ${EUID:-$(id -u)} -eq 0 ]] || {
  printf 'FAIL: profile package validation requires root inside the container.\n' >&2
  exit 1
}

install -d -m 0755 "$ROOT_DIR/build/test"
report="$ROOT_DIR/build/test/profile-package-plan.txt"

# The builder base image may carry a main-only deb822 source. Disable that
# ephemeral definition so the complete Kilimanjaro source list below is the
# single authority during this disposable resolution test.
if [[ -f /etc/apt/sources.list.d/debian.sources ]]; then
  mv /etc/apt/sources.list.d/debian.sources /tmp/debian.sources.disabled
fi

cat > /etc/apt/sources.list <<EOF
deb $DEBIAN_MIRROR $DEBIAN_SUITE main contrib non-free non-free-firmware
deb $DEBIAN_MIRROR $DEBIAN_SUITE-updates main contrib non-free non-free-firmware
deb $DEBIAN_SECURITY_MIRROR $DEBIAN_SUITE-security main contrib non-free non-free-firmware
EOF

dpkg --add-architecture i386
apt-get update

mapfile -t packages < <(
  awk 'NF && $1 !~ /^#/ { print $1 }' \
    "$ROOT_DIR"/overlay/usr/share/kilimanjaro/profiles/*.list | sort -u
)

printf 'Resolving %d packages across all Kilimanjaro software profiles...\n' "${#packages[@]}"
if apt-get install --simulate --no-install-recommends "${packages[@]}" > "$report"; then
  printf 'PASS: every native profile package resolves for %s/%s\n' "$DEBIAN_SUITE" "$ARCH"
  printf 'Report: %s\n' "$report"
else
  tail -n 100 "$report" >&2 || true
  printf 'FAIL: one or more profile packages could not be resolved.\n' >&2
  exit 1
fi
