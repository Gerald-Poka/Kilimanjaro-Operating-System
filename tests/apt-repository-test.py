#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Gerald Ndyamukama
"""Real signed APT integration tests, ONLY inside the disposable test container."""
import importlib.util
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def run(*args, success=True, cwd=None):
    result = subprocess.run(args, capture_output=True, text=True, cwd=cwd)
    if success and result.returncode:
        raise RuntimeError(f"{args[0]} failed:\n{result.stdout[-4000:]}\n{result.stderr[-4000:]}")
    if not success and result.returncode == 0:
        raise AssertionError("Invalid repository unexpectedly accepted")
    return result.stdout if success else result.stdout + result.stderr


def load(filename):
    spec = importlib.util.spec_from_file_location(filename.replace("-", "_"), ROOT / "scripts" / filename)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main():
    if os.geteuid() != 0 or not Path("/.dockerenv").exists():
        raise SystemExit("Run make container-apt-test: this test installs packages only in a disposable Docker container")
    packages = load("build-project-packages.py")
    repository = load("build-apt-repository.py")
    client = load("configure-apt-source.py")
    with tempfile.TemporaryDirectory(prefix="kilimanjaro-apt-test-", dir="/tmp") as work:
        work = Path(work)
        work.chmod(0o755)
        home = work / "gnupg"
        home.mkdir(mode=0o700)
        os.environ["GNUPGHOME"] = str(home)
        try:
            run("gpg", "--batch", "--pinentry-mode", "loopback", "--passphrase", "",
                "--quick-generate-key", "Kilimanjaro disposable APT test <test@example.invalid>",
                "ed25519", "sign", "1d")
            key = run("gpg", "--batch", "--with-colons", "--list-keys")
            fingerprint = next(line.split(":")[9] for line in key.splitlines() if line.startswith("fpr:"))
            first = work / "packages-v1"
            packages.build("0.1.0-1", first)
            repository.build(first, work / "repo-v1", fingerprint)
            generated = work / "client"
            client.generate("https://updates.example.invalid/apt", work / "repo-v1/kilimanjaro-archive-keyring.gpg", fingerprint, generated)
            assert "Signed-By:" in (generated / "kilimanjaro.sources").read_text()
            assert "trusted=yes" not in (generated / "kilimanjaro.sources").read_text()
            try:
                client.generate("https://updates.example.invalid", work / "repo-v1/kilimanjaro-archive-keyring.gpg", "0" * 40, work / "wrong-key")
                raise AssertionError("Wrong fingerprint accepted")
            except ValueError:
                pass
            print("PASS: public fingerprint validation and per-repository trust configuration", flush=True)
            for unsafe_url in ("http://updates.example.invalid", "https://user:password@example.invalid", "https://example.invalid/\nTrusted: yes"):
                try:
                    client.generate(unsafe_url, work / "repo-v1/kilimanjaro-archive-keyring.gpg", fingerprint, work / "invalid-url")
                    raise AssertionError("Unsafe repository URL accepted")
                except ValueError:
                    pass
            archive = work / "archive"
            shutil.copytree(work / "repo-v1", archive)
            keyring = Path("/etc/apt/keyrings/kilimanjaro-test.gpg")
            keyring.parent.mkdir(exist_ok=True)
            shutil.copyfile(archive / "kilimanjaro-archive-keyring.gpg", keyring)
            source = Path("/etc/apt/sources.list.d/kilimanjaro-test.sources")
            source.write_text(f"Types: deb\nURIs: file:{archive}\nSuites: uhuru\nComponents: main\nArchitectures: amd64\nSigned-By: {keyring}\n")
            shutil.copyfile(generated / "kilimanjaro.pref", "/etc/apt/preferences.d/kilimanjaro-test.pref")
            run("apt-get", "update", "--error-on=any")
            run("apt-get", "install", "-y", "--no-install-recommends", "kilimanjaro-base=0.1.0-1")
            assert run("dpkg-query", "-W", "-f=${Version}", "kilimanjaro-base") == "0.1.0-1"
            assert Path("/opt/kilimanjaro/bin/kilimanjaro-software").stat().st_mode & 0o111
            assert "kilimanjaro-base" in run("dpkg-query", "-S", "/usr/bin/kilimanjaro-hardware-report")
            profile = Path("/etc/kilimanjaro/profile")
            profile.write_text(profile.read_text() + "# user configuration retained\n")
            print("PASS: signed repository install, root-owned files and executable payload", flush=True)
            second = work / "packages-v2"
            packages.build("0.1.0-2", second)
            repository.build(second, work / "repo-v2", fingerprint)
            shutil.rmtree(archive)
            shutil.copytree(work / "repo-v2", archive)
            run("apt-get", "update", "--error-on=any")
            # Targeted upgrade avoids modifying unrelated Debian packages in this test.
            run("apt-get", "install", "-y", "--only-upgrade", "kilimanjaro-base")
            assert run("dpkg-query", "-W", "-f=${Version}", "kilimanjaro-base") == "0.1.0-2"
            assert "user configuration retained" in profile.read_text()
            assert "Candidate: 0.1.0-2" in run("apt-cache", "policy", "kilimanjaro-desktop")
            run("apt-get", "-s", "install", "kilimanjaro-desktop=0.1.0-2")
            print("PASS: APT version upgrade, preserved conffile and desktop dependency resolution", flush=True)
            expired = archive / "dists/uhuru/Release"
            metadata = expired.read_text()
            expired.write_text("\n".join("Valid-Until: Sat, 01 Jan 2000 00:00:00 GMT" if line.startswith("Valid-Until:") else line for line in metadata.splitlines()) + "\n")
            run("gpg", "--batch", "--yes", "--local-user", fingerprint, "--clearsign", "--output", str(archive / "dists/uhuru/InRelease"), str(expired))
            failure = run("apt-get", "update", "--error-on=any", success=False)
            assert "expired" in failure.lower()
            print("PASS: correctly signed but expired metadata rejected by APT", flush=True)
            shutil.copyfile(work / "repo-v2/dists/uhuru/InRelease", archive / "dists/uhuru/InRelease")
            run("apt-get", "update", "--error-on=any")
            # A signature authenticates metadata; its hashes authenticate packages.
            downloads = work / "downloads"
            downloads.mkdir(mode=0o755)
            run("apt-get", "download", "kilimanjaro-desktop=0.1.0-2", cwd=downloads)
            for downloaded in downloads.glob("*.deb"):
                downloaded.unlink()
            deb = next((archive / "pool/main").glob("kilimanjaro-desktop*.deb"))
            with deb.open("ab") as stream:
                stream.write(b"tampered")
            failure = run("apt-get", "download", "kilimanjaro-desktop=0.1.0-2", success=False, cwd=downloads)
            assert "Hash Sum mismatch" in failure or "unexpected size" in failure
            print("PASS: tampered package rejected by APT", flush=True)
            release = archive / "dists/uhuru/InRelease"
            release.write_bytes(release.read_bytes().replace(b"Kilimanjaro Development", b"Kilimanjaro Untrusted!!"))
            failure = run("apt-get", "update", "--error-on=any", success=False)
            assert any(word in failure.lower() for word in ("signature", "manipulated", "signed"))
            print("PASS: tampered signed metadata rejected by APT", flush=True)
            # Remove both authentication paths: do not silently fall back to an unsigned Release.
            release.unlink()
            (archive / "dists/uhuru/Release.gpg").unlink()
            failure = run("apt-get", "update", "--error-on=any", success=False)
            assert "not signed" in failure.lower() or "no longer signed" in failure.lower()
            print("PASS: unsigned repository rejected by APT", flush=True)
        finally:
            subprocess.run(["gpgconf", "--kill", "gpg-agent"], check=False)


if __name__ == "__main__":
    main()
