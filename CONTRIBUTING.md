# Contributing to Kilimanjaro OS

Thank you for helping improve Kilimanjaro OS. The project is experimental;
contributions do not imply that a feature is qualified for a stable release.

## Propose and submit changes

1. Open an issue or discussion for substantial changes so the scope can be
   agreed before implementation.
2. Fork the public repository and create a focused branch in your fork.
   Contributors do not need write access to this repository.
3. Make the smallest complete change, update related documentation, and do not
   include generated ISOs, VM disks, build output, credentials, or private keys.
4. Run the relevant checks below and describe their results in your pull request.
5. Submit a pull request against `main`. A project owner review is required
   before contributor changes are merged. Please allow time for review and
   respond to requested changes.

## Maintainer: enable the merge gate

The files in this repository describe the review policy, but GitHub does not
enforce it until branch protection is configured. In repository settings, add
a branch rule or ruleset for `main` with:

- Require a pull request before merging and one approval.
- Require approval from a code owner; `.github/CODEOWNERS` assigns the project
  to `@Gerald-Poka`.
- Dismiss stale approvals when new commits are pushed.
- Require the `Source validation` and `Website tests and build` checks.
- Block force pushes and branch deletion.

Keep the owner's administrator bypass available for owner work or urgent fixes.
Do not grant routine contributors write access: public contributors can fork
the repository and submit pull requests. Owner-authored pull requests cannot be
approved by their author, so use the administrator bypass when appropriate.

## Checks

For source changes, run from the repository root:

```bash
make validate
```

For website changes, also run:

```bash
cd website
npm ci
npm test
npm run build
```

For OS image changes, follow [the development workflow](docs/DEVELOPMENT.md).
Building an ISO requires a supported Debian/Ubuntu build environment, Podman or
Docker, substantial free disk space, and can take significant time. Run the
image and VM checks when the required build artifact and host tools are
available; state clearly which checks you could not run.

Never test the installer on a personal or production disk. Use a disposable VM
and follow the [installation safety procedure](docs/INSTALLATION.md). Do not
write to a physical USB device unless its contents can be erased and the device
has been explicitly selected.

## Project expectations

- Preserve the development-status and hardware-qualification disclaimers.
- Keep package choices, claims, and test evidence aligned with the actual image.
- Do not commit credentials, private signing keys, personal test data, or
  generated releases.
- Preserve upstream licenses, notices, attribution, and third-party terms.
- Keep changes focused and explain user-visible or security-sensitive behavior.
