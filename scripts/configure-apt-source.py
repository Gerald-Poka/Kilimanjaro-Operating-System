#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Gerald Ndyamukama
"""Generate reviewed client files, not install them or alter the host's APT."""
import argparse
from pathlib import Path
import re
import subprocess
from urllib.parse import urlsplit


def generate(url, key, fingerprint, output):
    parsed = urlsplit(url)
    if (parsed.scheme != "https" or not parsed.hostname or parsed.username or
            parsed.password or parsed.query or parsed.fragment or
            re.search(r"[\s\\]", url)):
        raise ValueError("Use a plain HTTPS repository URL, without credentials or query")
    if not re.fullmatch(r"(?:[a-fA-F0-9]{40}|[a-fA-F0-9]{64})", fingerprint):
        raise ValueError("Supply the independently verified full fingerprint")
    info = subprocess.run(["gpg", "--batch", "--with-colons", "--show-keys", str(key)],
                          check=True, capture_output=True, text=True).stdout
    primary = []
    awaiting = False
    for line in info.splitlines():
        fields = line.split(":")
        if fields[0] == "pub":
            awaiting = True
        elif fields[0] == "fpr" and awaiting:
            primary.append(fields[9].upper())
            awaiting = False
        elif fields[0] in ("sec", "ssb"):
            raise ValueError("Only a public key is accepted")
    if primary != [fingerprint.upper()]:
        raise ValueError("Public key identity differs from the trusted fingerprint")
    if output.exists():
        raise ValueError("Output exists; review changes before replacing client files")
    output.mkdir(parents=True)
    # Package-independent trust installation; neither apt-key nor trusted=yes.
    public = subprocess.run(["gpg", "--batch", "--yes", "--dearmor"],
                            input=key.read_bytes(), check=True, capture_output=True).stdout
    (output / "kilimanjaro-archive-keyring.gpg").write_bytes(public)
    (output / "kilimanjaro.sources").write_text(
        f"Types: deb\nURIs: {url.rstrip('/')}\nSuites: uhuru\nComponents: main\n"
        "Architectures: amd64\n"
        "Signed-By: /etc/apt/keyrings/kilimanjaro-archive-keyring.gpg\n"
        "Check-Valid-Until: yes\n"
    )
    (output / "kilimanjaro.pref").write_text(
        "Package: kilimanjaro-*\nPin: release o=Kilimanjaro\nPin-Priority: 600\n\n"
        "Package: *\nPin: release o=Kilimanjaro\nPin-Priority: -1\n"
    )
    print(f"Client configuration generated for review: {output}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--url", required=True)
    parser.add_argument("--public-key", required=True, type=Path)
    parser.add_argument("--fingerprint", required=True)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    generate(args.url, args.public_key.resolve(), args.fingerprint, args.output.resolve())
