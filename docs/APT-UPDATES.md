# Kilimanjaro updates: Debian now, project repository after activation

Kilimanjaro is Debian-based and uses **APT**, not Fedora's DNF. Debian's
`trixie`, `trixie-updates` and `trixie-security` repositories remain configured.
Manual APT operations are available even though background upgrade timers are
disabled. On an installed test system, back up first and run:

```sh
sudo apt update
sudo apt upgrade
```

Review the proposed changes; do not run another package operation concurrently.
Reboot when a kernel or other component requires it, then check the desktop and
devices. Flatpak applications have their own `flatpak update` path. Live-session
updates do not persist after reboot unless suitable persistence is configured.

## Implemented project packaging

- `kilimanjaro-base`: original first-boot/software/network utilities, catalogue,
  profiles, PolicyKit action and project-specific service/configuration files.
- `kilimanjaro-desktop`: Welcome GUI, tray monitor, web launchers and project
  themes/icons/wallpapers. It requires the matching base-package version.
- `packaging/packages.json` is the reviewed payload allowlist. The packages do
  not own Debian's repository definitions, kernel, global `os-release`, user
  home directories or generic SDDM/KDE configuration.
- `/etc` files are dpkg conffiles. Upgrades do not silently reset local edits.
  Maintainer hooks reload unit definitions only; they do not rerun first boot,
  restart the desktop, enroll keys or perform network operations.
- The ISO configure stage now installs these packages into its build root.
  Existing older ISOs need a tested migration before gaining project updates.

Build on Debian, or use the Debian toolchain container:

```sh
make container-project-packages CONTAINER_ENGINE=docker PACKAGE_VERSION=0.1.0-1
```

Generated `.deb` files and the exact corresponding project-source archive go
under `output/packages/`. A published version must never be reused for different
bytes. Bump the Debian package revision (`-2`, `-3`, etc.) for project changes,
and archive the previous artifacts. This is not a whole-OS rollback mechanism.

## Build a signed repository snapshot

Requires `apt-utils`, `dpkg-dev`, Python, GnuPG and `gpgv`. Use an owner-controlled
archive signing key with a full fingerprint; this is separate from SSH access
and from ISO Secure Boot signing. Do not place private keys in the repository,
ISO, static hosting folder or container image. Tests use disposable keys only.
Replace example fingerprints, URLs and file paths below with reviewed values;
the placeholders intentionally cannot activate a real repository.

```sh
python3 scripts/build-apt-repository.py \
  --packages output/packages \
  --output output/apt-snapshots/snapshot-001 \
  --fingerprint FULL_ARCHIVE_KEY_FINGERPRINT
```

The generator accepts only the two reviewed package names, includes corresponding
source archives, creates package indexes and `Release`, and signs `InRelease`
and `Release.gpg`. It verifies the signatures before moving a staged snapshot
to its new destination. Repository metadata expires after 14 days; refresh and
re-sign before expiry even when package versions do not change. Do not disable
expiry checks to conceal missed maintenance. Signed metadata is not proof that
the software itself is free of vulnerabilities.

## Activation — intentionally not performed yet

The owner chose hosting **after local tests**. There is no active public project
APT endpoint, trusted project archive key or supported offline update bundle.
Do not advertise project updates as available until activation is verified.

1. Choose HTTPS hosting for the snapshot's entire directory tree. Keep pool
   artifacts immutable and retain old package URLs. Publish pool files and
   indexes before switching metadata; use by-hash/atomic hosting where possible
   to avoid mixed-snapshot errors. Monitor availability and metadata expiry.
2. Establish archive-key custody, expiry, revocation and key rotation. Publish
   the full fingerprint through a trusted independent channel. A downloaded
   key from the same server alone does not establish publisher identity.
3. Generate client files after independently checking the fingerprint:

   ```sh
   python3 scripts/configure-apt-source.py \
     --url https://YOUR-REVIEWED-HOST/apt \
     --public-key PATH_TO_PUBLIC_ARCHIVE_KEY \
     --fingerprint FULL_ARCHIVE_KEY_FINGERPRINT \
     --output output/apt-client
   ```

   This writes files for review only; it does not install or activate them.
   After checking them, install the public key as
   `/etc/apt/keyrings/kilimanjaro-archive-keyring.gpg`, source definition as
   `/etc/apt/sources.list.d/kilimanjaro.sources` and pinning as
   `/etc/apt/preferences.d/kilimanjaro.pref`, root-owned/readable. No `apt-key`,
   `trusted=yes` or disabled signature verification is used. Pinning allows
   project package names but excludes unrelated Debian packages from this origin.
4. Test the HTTPS source in a fresh disposable client: verify `apt update`,
   `apt-cache policy kilimanjaro-base kilimanjaro-desktop`, installation and
   upgrades. Test invalid signatures, expired metadata and altered downloads.
   Confirm Debian security sources still work and no unrelated packages change.
5. Add verified public-key/source configuration to a new ISO, qualify installed
   upgrades/reboot/recovery, and only then publish updated user instructions.

If the activated project source is unavailable or expired, fix the hosting or
refresh its signed metadata; never disable signature/expiry checks. An administrator
can temporarily set `Enabled: no` in **only** `kilimanjaro.sources`, leave Debian's
sources intact, and refresh Debian updates. Project-specific updates then pause;
re-enable that source only after its valid signed metadata is restored. This is
an explicit fallback procedure, not automatic recovery or a reason to ignore errors.

## Integration test and limits

```sh
make container-apt-test CONTAINER_ENGINE=docker
```

Runs only inside a disposable Docker container; it refuses native execution.
It tests real APT installation and upgrade of the actual base package, edited
conffile preservation, desktop dependency resolution and rejection of modified
packages, signed metadata and unsigned repositories. It does not certify a
graphical desktop upgrade, whole-system/kernel upgrades, public HTTPS hosting,
owner key identity, rotation, or snapshot recovery. Correctly signed but expired
metadata is also rejected. No physical disks are used.

Authoritative references: [APT authentication](https://manpages.debian.org/trixie/apt/apt-secure.8.en.html),
[Debian package management](https://www.debian.org/doc/manuals/debian-reference/ch02),
and [configuration-file handling](https://www.debian.org/doc/debian-policy/ap-pkg-conffiles.html).
