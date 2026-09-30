#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Gerald Ndyamukama
"""Build scoped project packages without owning Debian's global configuration."""
import argparse
import json
from pathlib import Path
import re
import shutil
import subprocess
import tarfile
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def run(*args):
    return subprocess.run(args, check=True, text=True, capture_output=True).stdout


def build(version, output):
    if not re.fullmatch(r"[0-9][A-Za-z0-9.+~:-]*", version):
        raise ValueError("Invalid Debian version")
    run("dpkg", "--validate-version", version)
    output.mkdir(parents=True, exist_ok=True)
    source_archive = output / f"kilimanjaro-source_{version}.tar.gz"
    if source_archive.exists():
        raise ValueError("Source archive already exists; use a new version or output directory")
    manifest = json.loads((ROOT / "packaging/packages.json").read_text())
    artifacts = []
    for name, spec in manifest.items():
        artifact = output / f"{name}_{version}_all.deb"
        if artifact.exists():
            raise ValueError(f"Refusing to overwrite versioned package: {artifact}")
        with tempfile.TemporaryDirectory(prefix="kilimanjaro-package-") as work:
            stage = Path(work) / name
            stage.mkdir()
            for relative in spec["paths"]:
                path = Path(relative)
                if path.is_absolute() or ".." in path.parts:
                    raise ValueError("Unsafe package manifest")
                source = ROOT / "overlay" / path
                if source.is_symlink() or not source.resolve().is_relative_to((ROOT / "overlay").resolve()):
                    raise ValueError("Payload path escapes the project overlay")
                if not source.exists():
                    raise ValueError(f"Missing package payload: {source}")
                entries = sorted(source.rglob("*")) if source.is_dir() else [source]
                for entry in entries:
                    if entry.is_symlink():
                        raise ValueError(f"Review symlink before packaging: {entry}")
                    if not entry.resolve().is_relative_to((ROOT / "overlay").resolve()):
                        raise ValueError("Payload entry escapes the project overlay")
                    if not entry.is_file() or "__pycache__" in entry.parts or entry.suffix == ".pyc":
                        continue
                    destination = stage / entry.relative_to(ROOT / "overlay")
                    destination.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copyfile(entry, destination)
                    executable = ("bin" in path.parts or destination.suffix == ".py") and not destination.suffix == ".json"
                    destination.chmod(0o755 if executable else 0o644)
            if name == "kilimanjaro-base":
                destination = stage / "usr/bin/kilimanjaro-hardware-report"
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / "scripts/hardware-report.sh", destination)
                destination.chmod(0o755)
            documentation = stage / "usr/share/doc" / name
            documentation.mkdir(parents=True, exist_ok=True)
            for document in ("LICENSE", "LICENSING.md"):
                shutil.copyfile(ROOT / document, documentation / document)
            (documentation / "copyright").write_text(
                "Original program code: Copyright 2026 Gerald Ndyamukama; GPL-3.0-only.\n"
                "See LICENSE and LICENSING.md. Existing theme/wallpaper licenses remain\n"
                "GPL-3.0-or-later / CC-BY-SA-4.0 as declared in component metadata.\n"
                "Artwork provenance review remains a public-release gate.\n"
            )
            control = stage / "DEBIAN"
            control.mkdir()
            size = sum(p.stat().st_size for p in stage.rglob("*") if p.is_file()) // 1024
            (control / "control").write_text(
                f"Package: {name}\nVersion: {version}\nArchitecture: all\n"
                f"Maintainer: Gerald Ndyamukama <geraldndyamukama39@gmail.com>\n"
                f"Depends: {spec['depends'].format(version=version)}\n"
                f"Installed-Size: {size}\nSection: misc\nPriority: optional\n"
                "Homepage: https://github.com/Gerald-Poka/Kilimanjaro-Operating-System\n"
                f"Description: {spec['description']}\n"
                " Development package for the Debian 13 Kilimanjaro desktop.\n"
            )
            conffiles = sorted("/" + str(p.relative_to(stage)) for p in (stage / "etc").rglob("*") if p.is_file())
            (control / "conffiles").write_text("\n".join(conffiles) + "\n")
            # Reload unit definitions only. Never rerun first boot, restart the
            # desktop, overwrite user settings or change repository trust.
            for hook in ("postinst", "postrm"):
                (control / hook).write_text(
                    "#!/bin/sh\nset -e\n"
                    "if [ -d /run/systemd/system ]; then\n"
                    "  systemctl daemon-reload\nfi\nexit 0\n"
                )
                (control / hook).chmod(0o755)
            for directory in stage.rglob("*"):
                if directory.is_dir():
                    directory.chmod(0o755)
            run("dpkg-deb", "--root-owner-group", "--build", str(stage), str(artifact))
            artifacts.append(artifact)
            print(artifact)
    # Exact build inputs alongside binary packages; no dependencies, private
    # credentials, host reports, Git history or generated output are included.
    with tarfile.open(source_archive, "w:gz") as archive:
        for relative in ("LICENSE", "LICENSING.md", "packaging", "scripts/build-project-packages.py", "scripts/hardware-report.sh", "overlay"):
            source = ROOT / relative
            entries = sorted(source.rglob("*")) if source.is_dir() else [source]
            for entry in entries:
                if entry.is_symlink():
                    raise ValueError("Review source symlink before archiving")
                if entry.is_file() and "__pycache__" not in entry.parts and entry.suffix != ".pyc":
                    archive.add(entry, arcname=f"kilimanjaro-source-{version}/{entry.relative_to(ROOT)}", recursive=False)
    print(source_archive)
    return artifacts


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", default="0.1.0-1")
    parser.add_argument("--output", type=Path, default=ROOT / "output/packages")
    args = parser.parse_args()
    build(args.version, args.output.resolve())
