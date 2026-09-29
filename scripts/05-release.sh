#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Gerald Ndyamukama
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_command sha256sum
[[ -f "$ISO_PATH" ]] || die "ISO does not exist: $ISO_PATH"

signing_key=${KILIMANJARO_GPG_KEY:-}
if [[ -n "$signing_key" ]]; then
  [[ "$signing_key" =~ ^([[:xdigit:]]{40}|[[:xdigit:]]{64})$ ]] || \
    die 'KILIMANJARO_GPG_KEY must be a full GPG fingerprint, not an email or short key ID.'
  require_command gpg
fi

release_stage=$(mktemp -d "$OUTPUT_DIR/.release-XXXXXX")
release_stage=$(cd -- "$release_stage" && pwd)
cleanup() {
  rm -f -- "$release_stage/SHA256SUMS" "$release_stage/ISO.sig" \
    "$release_stage/SHA256SUMS.sig" "$release_stage/release-key.asc" \
    "$release_stage/release-key.fingerprint"
  rmdir -- "$release_stage" 2>/dev/null || true
}
trap cleanup EXIT
# These exact generated files must not imply a rebuilt ISO is still authenticated.
rm -f -- "$ISO_PATH.sig" "$OUTPUT_DIR/SHA256SUMS.sig"

log 'Writing SHA256SUMS for the exact release artifact'
(
  cd "$OUTPUT_DIR"
  sha256sum "$ISO_BASENAME" > "$release_stage/SHA256SUMS"
)

if [[ -n "$signing_key" ]]; then
  log "Signing ISO and checksum manifest with key $signing_key"
  gpg --batch --yes --local-user "$signing_key" \
    --armor --detach-sign --output "$release_stage/ISO.sig" "$ISO_PATH"
  gpg --batch --yes --local-user "$signing_key" \
    --armor --detach-sign --output "$release_stage/SHA256SUMS.sig" "$release_stage/SHA256SUMS"
  gpg --batch --verify "$release_stage/ISO.sig" "$ISO_PATH"
  gpg --batch --verify "$release_stage/SHA256SUMS.sig" "$release_stage/SHA256SUMS"
  gpg --batch --armor --export "$signing_key" > "$release_stage/release-key.asc"
  [[ -s "$release_stage/release-key.asc" ]] || die 'Public signing key export is empty.'
  printf '%s\n' "$signing_key" > "$release_stage/release-key.fingerprint"
  mv -f -- "$release_stage/SHA256SUMS" "$OUTPUT_DIR/SHA256SUMS"
  mv -f -- "$release_stage/ISO.sig" "$ISO_PATH.sig"
  mv -f -- "$release_stage/SHA256SUMS.sig" "$OUTPUT_DIR/SHA256SUMS.sig"
  mv -f -- "$release_stage/release-key.asc" "$OUTPUT_DIR/release-key.asc"
  mv -f -- "$release_stage/release-key.fingerprint" "$OUTPUT_DIR/release-key.fingerprint"
  log 'Both detached signatures verified; only the public verification key was exported.'
else
  mv -f -- "$release_stage/SHA256SUMS" "$OUTPUT_DIR/SHA256SUMS"
  log 'KILIMANJARO_GPG_KEY is unset; release artifacts were checksummed but not signed.'
fi

log "Release artifacts are in $OUTPUT_DIR"
