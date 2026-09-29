#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Gerald Ndyamukama
"""Exercise release failure handling with tiny files and a mock GPG executable.

This tests orchestration, not real cryptographic authentication or a release key.
"""
import hashlib
import os
import shutil
from pathlib import Path
import subprocess
import tempfile
import unittest

PROJECT = Path(__file__).resolve().parents[1]
ISO_NAME = "kilimanjaro-os-0.1.0-amd64.iso"
FINGERPRINT = "A" * 40


class ReleaseTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="kilimanjaro-release-test-")
        self.addCleanup(self.temp.cleanup)
        self.output = Path(self.temp.name)
        self.iso = self.output / ISO_NAME
        self.iso.write_bytes(b"development fixture, not an ISO\n")
        self.bin = self.output / "bin"
        self.bin.mkdir()
        mock = self.bin / "gpg"
        mock.write_text('''#!/usr/bin/env bash
set -euo pipefail
if [[ " $* " == *" --verify "* ]]; then
  [[ ${MOCK_VERIFY_FAIL:-0} != 1 ]]
elif [[ " $* " == *" --export "* ]]; then
  printf 'mock public key\\n'
else
  while [[ $# -gt 0 ]]; do
    if [[ $1 == --output ]]; then
      shift
      [[ ${MOCK_SIGN_FAIL:-0} != 1 ]] || exit 3
      printf 'mock signature\\n' > "$1"
      break
    fi
    shift
  done
fi
''', encoding="utf-8")
        mock.chmod(0o700)
        self.env = dict(os.environ, KILIMANJARO_OUTPUT_DIR=str(self.output),
                        KILIMANJARO_GPG_KEY="", PATH=f"{self.bin}:{os.environ['PATH']}")

    def run_release(self):
        return subprocess.run(["bash", str(PROJECT / "scripts/05-release.sh")],
                              env=self.env, capture_output=True, text=True)

    def stale_signatures(self):
        for file in [f"{ISO_NAME}.sig", "SHA256SUMS.sig"]:
            (self.output / file).write_text("stale signature", encoding="utf-8")

    def assert_no_signatures_or_stage(self):
        self.assertFalse((self.output / f"{ISO_NAME}.sig").exists())
        self.assertFalse((self.output / "SHA256SUMS.sig").exists())
        self.assertEqual(list(self.output.glob(".release-*")), [])

    def test_unsigned_rebuild_clears_stale_signatures(self):
        self.stale_signatures()
        result = self.run_release()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assert_no_signatures_or_stage()
        expected = hashlib.sha256(self.iso.read_bytes()).hexdigest()
        self.assertEqual((self.output / "SHA256SUMS").read_text(), f"{expected}  {ISO_NAME}\n")

    def test_short_key_id_rejected_before_existing_artifacts_change(self):
        self.stale_signatures()
        self.env["KILIMANJARO_GPG_KEY"] = "ABCD1234"
        result = self.run_release()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("full GPG fingerprint", result.stderr)
        self.assertEqual((self.output / f"{ISO_NAME}.sig").read_text(), "stale signature")

    def test_signing_failure_cannot_publish_partial_signatures(self):
        self.stale_signatures()
        self.env.update(KILIMANJARO_GPG_KEY=FINGERPRINT, MOCK_SIGN_FAIL="1")
        self.assertNotEqual(self.run_release().returncode, 0)
        self.assert_no_signatures_or_stage()

    def test_failed_verification_cannot_publish_signatures(self):
        self.env.update(KILIMANJARO_GPG_KEY=FINGERPRINT, MOCK_VERIFY_FAIL="1")
        self.assertNotEqual(self.run_release().returncode, 0)
        self.assert_no_signatures_or_stage()

    def test_mock_success_exports_only_public_key_and_fingerprint(self):
        self.env["KILIMANJARO_GPG_KEY"] = FINGERPRINT
        result = self.run_release()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.output / f"{ISO_NAME}.sig").is_file())
        self.assertTrue((self.output / "SHA256SUMS.sig").is_file())
        self.assertEqual((self.output / "release-key.asc").read_text(), "mock public key\n")
        self.assertEqual((self.output / "release-key.fingerprint").read_text(), FINGERPRINT + "\n")
        self.assertEqual(list(self.output.glob(".release-*")), [])

    @unittest.skipUnless(shutil.which("gpg") and shutil.which("gpgconf"), "GnuPG not installed")
    def test_real_signatures_verify_in_clean_keyring_and_reject_tampering(self):
        # A throwaway test identity, not Gerald's release key. No host keyring
        # is read or modified, and no secret key is exported to release output.
        signer = self.output / "test-keyring"
        verifier = self.output / "verification-keyring"
        signer.mkdir(mode=0o700)
        verifier.mkdir(mode=0o700)
        real_env = dict(os.environ, GNUPGHOME=str(signer),
                        KILIMANJARO_OUTPUT_DIR=str(self.output))

        def gpg(home, *args):
            return subprocess.run([shutil.which("gpg"), "--homedir", str(home),
                                   "--batch", *args], capture_output=True, text=True)

        try:
            result = gpg(signer, "--pinentry-mode", "loopback", "--passphrase", "",
                         "--quick-generate-key", "Kilimanjaro temporary test <test@example.invalid>",
                         "ed25519", "sign", "1d")
            self.assertEqual(result.returncode, 0, result.stderr)
            listed = gpg(signer, "--with-colons", "--list-keys")
            fingerprint = next(line.split(":")[9] for line in listed.stdout.splitlines()
                               if line.startswith("fpr:"))
            real_env["KILIMANJARO_GPG_KEY"] = fingerprint
            result = subprocess.run(["bash", str(PROJECT / "scripts/05-release.sh")],
                                    env=real_env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            imported = gpg(verifier, "--import", str(self.output / "release-key.asc"))
            self.assertEqual(imported.returncode, 0, imported.stderr)
            listed = gpg(verifier, "--with-colons", "--list-keys")
            self.assertIn(fingerprint, listed.stdout)
            for signature, artifact in [(f"{ISO_NAME}.sig", ISO_NAME),
                                        ("SHA256SUMS.sig", "SHA256SUMS")]:
                result = gpg(verifier, "--verify", str(self.output / signature),
                             str(self.output / artifact))
                self.assertEqual(result.returncode, 0, result.stderr)
            self.iso.write_bytes(b"tampered fixture\n")
            self.assertNotEqual(gpg(verifier, "--verify", str(self.output / f"{ISO_NAME}.sig"),
                                   str(self.iso)).returncode, 0)
            (self.output / "SHA256SUMS").write_text("tampered manifest\n", encoding="utf-8")
            self.assertNotEqual(gpg(verifier, "--verify", str(self.output / "SHA256SUMS.sig"),
                                   str(self.output / "SHA256SUMS")).returncode, 0)
        finally:
            for home in [signer, verifier]:
                subprocess.run([shutil.which("gpgconf"), "--homedir", str(home), "--kill", "all"],
                               capture_output=True)


if __name__ == "__main__":
    unittest.main()
