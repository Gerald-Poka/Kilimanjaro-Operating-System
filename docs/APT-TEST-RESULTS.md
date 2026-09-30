# APT integration evidence — 30 September 2026

Command: `DOCKER_CONTEXT=default make container-apt-test CONTAINER_ENGINE=docker`.
Environment: disposable Debian 13 Docker container; read-only source mount,
no host APT modifications, physical disks or owner signing keys.

Passed checks:

1. Build actual `kilimanjaro-base` and `kilimanjaro-desktop` packages with exact
   corresponding project-source archives.
2. Generate and verify signed `InRelease`/`Release.gpg` with an isolated,
   disposable Ed25519 key; validate the public fingerprint for client configuration.
3. APT installs the actual base package at `0.1.0-1` from the signed repository.
4. Publish a local test snapshot at `0.1.0-2`; APT upgrades the base package,
   retains an edited `/etc/kilimanjaro/profile` conffile and resolves desktop
   package dependencies. Runtime files have executable permissions.
5. APT rejects correctly signed but expired metadata.
6. An unmodified desktop package downloads successfully; APT rejects that
   package after its contents are altered, using signed-index size/hash checks.
7. APT rejects modified signed metadata and a repository with no signatures.

The temporary test keyring and repository are removed with the disposable
container. These test keys do not identify Gerald or authenticate a public
Kilimanjaro release. Generated production package artifacts contain no keys.

This does **not** prove installed graphical upgrades, kernel-update reboot,
snapshot restoration, public HTTPS repository operation, key rotation or
physical hardware support. The owner chose hosting after local tests; public
activation and the trusted archive key remain pending.

See [implementation and activation instructions](APT-UPDATES.md).
