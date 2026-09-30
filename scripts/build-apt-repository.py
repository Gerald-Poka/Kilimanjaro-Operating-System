#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Gerald Ndyamukama
"""Create a new immutable signed repository snapshot; never publish automatically."""
import argparse
from datetime import datetime, timedelta, timezone
from email.utils import format_datetime
import gzip
import hashlib
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
ALLOWED = {"kilimanjaro-base", "kilimanjaro-desktop"}


def command(*args, cwd=None):
    return subprocess.run(args, cwd=cwd, check=True, capture_output=True).stdout


def build(packages, output, fingerprint):
    if not re.fullmatch(r"(?:[a-fA-F0-9]{40}|[a-fA-F0-9]{64})", fingerprint):
        raise ValueError("Supply the full archive signing-key fingerprint")
    if output.exists():
        raise ValueError("Repository destination exists; use a new snapshot directory")
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".apt-stage-", dir=output.parent) as work:
        stage = Path(work) / "repository"
        pool = stage / "pool/main"
        pool.mkdir(parents=True)
        seen = set()
        for artifact in sorted(packages.glob("*.deb")):
            if artifact.is_symlink():
                raise ValueError("Symlink packages are not accepted")
            name = command("dpkg-deb", "-f", str(artifact), "Package").decode().strip()
            arch = command("dpkg-deb", "-f", str(artifact), "Architecture").decode().strip()
            version = command("dpkg-deb", "-f", str(artifact), "Version").decode().strip()
            if name not in ALLOWED or arch != "all" or not re.fullmatch(r"[0-9][A-Za-z0-9.+~:-]*", version):
                raise ValueError("Repository accepts only reviewed Kilimanjaro packages")
            identity = (name, version, arch)
            if identity in seen:
                raise ValueError("Duplicate package identity")
            seen.add(identity)
            shutil.copyfile(artifact, pool / f"{name}_{version}_all.deb")
        if {item[0] for item in seen} != ALLOWED:
            raise ValueError("Both Kilimanjaro packages are required")
        for version in {item[1] for item in seen}:
            source = packages / f"kilimanjaro-source_{version}.tar.gz"
            if not source.is_file() or source.is_symlink():
                raise ValueError("Each package version requires its exact source archive")
            sources = stage / "pool/source"
            sources.mkdir(exist_ok=True)
            shutil.copyfile(source, sources / source.name)
        release_dir = stage / "dists/uhuru"
        for architecture in ("amd64", "all"):
            index = release_dir / f"main/binary-{architecture}/Packages"
            index.parent.mkdir(parents=True)
            content = command("apt-ftparchive", "packages", "pool", cwd=stage)
            index.write_bytes(content)
            index.with_suffix(".gz").write_bytes(gzip.compress(content, mtime=0))
        valid_until = format_datetime(datetime.now(timezone.utc) + timedelta(days=14), usegmt=True)
        release = command("apt-ftparchive",
                          "-o", "APT::FTPArchive::Release::Origin=Kilimanjaro",
                          "-o", "APT::FTPArchive::Release::Label=Kilimanjaro Development",
                          "-o", "APT::FTPArchive::Release::Suite=uhuru",
                          "-o", "APT::FTPArchive::Release::Codename=uhuru",
                          "-o", "APT::FTPArchive::Release::Architectures=amd64 all",
                          "-o", "APT::FTPArchive::Release::Components=main",
                          "release", "dists/uhuru", cwd=stage)
        (release_dir / "Release").write_bytes(release + f"Valid-Until: {valid_until}\n".encode())
        common = ("gpg", "--batch", "--yes", "--local-user", fingerprint)
        command(*common, "--clearsign", "--output", str(release_dir / "InRelease"), str(release_dir / "Release"))
        command(*common, "--armor", "--detach-sign", "--output", str(release_dir / "Release.gpg"), str(release_dir / "Release"))
        key = command("gpg", "--batch", "--export", fingerprint)
        if not key:
            raise ValueError("Empty public key export")
        (stage / "kilimanjaro-archive-keyring.gpg").write_bytes(key)
        (stage / "archive-key.fingerprint").write_text(fingerprint.upper() + "\n")
        verify = ("gpgv", "--keyring", str(stage / "kilimanjaro-archive-keyring.gpg"))
        command(*verify, str(release_dir / "InRelease"))
        command(*verify, str(release_dir / "Release.gpg"), str(release_dir / "Release"))
        lines = []
        for entry in sorted(stage.rglob("*")):
            if entry.is_file():
                lines.append(f"{hashlib.sha256(entry.read_bytes()).hexdigest()}  {entry.relative_to(stage)}")
        (stage / "SHA256SUMS").write_text("\n".join(lines) + "\n")
        stage.rename(output)
        print(f"Signed repository snapshot: {output}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--packages", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--fingerprint", required=True)
    args = parser.parse_args()
    build(args.packages.resolve(), args.output.resolve(), args.fingerprint)
