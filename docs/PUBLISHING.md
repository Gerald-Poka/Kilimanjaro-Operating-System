# Source publication and ISO release readiness

Making the source repository public is a different decision from releasing a
production ISO. This checklist does not certify legal compliance, hardware
compatibility or security. The current image remains a development build.

## Source repository: before the first public push

- Choose the license for original Kilimanjaro code and documentation, and a
  suitable policy/license for original artwork. Confirm ownership or permission
  for every contributed or externally sourced file before applying that license.
- Add the actual license text and scope, preserving any upstream licenses,
  attribution and copyright notices. A root license must not purport to relicense
  Debian, KDE or proprietary applications included in an ISO.
- Inventory third-party/adapted files and record their origins and licenses.
  Do not replace upstream application authors with the project author's name.
- Exclude generated root filesystems, ISOs, VM disks, node_modules, build output,
  credentials and private signing keys. The ignore rules are a precaution, not a
  secret audit: already tracked files and old commits need their own inspection.
- Inspect the complete proposed tracked-file list and all Git history before
  publishing. If a credential was committed, revoke/rotate it; merely deleting
  the file does not remove it from earlier commits or invalidate the credential.
- Confirm the public contact email/WhatsApp number and author details are intended
  for public disclosure. Avoid publishing hardware serials, private test logs or
  personal documents.
- Keep the README explicit about development status and passed/pending tests.
  Do not label the source or ISO stable, certified or fully supported without evidence.

A public repository alone is not automatically open source. GitHub explains the
effect of publishing without a license in its
[repository licensing guidance](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/licensing-a-repository).

## ISO redistribution: additional requirements

- Produce an exact package/version inventory for the final image, including
  firmware, fonts, codecs and non-free components. Review the installed copyright
  files and relevant vendor terms for redistribution and other obligations.
- Preserve required notices and license texts. Supply the corresponding source
  and build/installation material in the manner required by each applicable
  license; a repository of Kilimanjaro scripts alone is not necessarily the
  corresponding source for every binary in the ISO. Do not assume a link to an
  upstream repository is sufficient for every license/version/distribution method.
- Keep optional vendor downloads optional unless bundling rights are confirmed.
  Vendor accounts, API subscriptions and game licenses are not provided by the OS.
- Complete the acceptance gates in [INSTALLATION.md](INSTALLATION.md), including
  installed graphical sessions, updates/recovery and the hardware matrix. Mark
  any intentionally unqualified test build accurately rather than claiming those
  tests passed.
- Review website hosting/logging, external-service disclosures, trademark usage
  and applicable distribution/privacy obligations before public launch. The legal
  website notice is not a finalized EULA or a professional legal opinion.

References: [Debian license categories](https://www.debian.org/legal/licenses/)
and [Debian package copyright guidance](https://www.debian.org/legal/disclaimer/).

## Release-signing workflow

1. Complete the required VM acceptance tests before generating the new release
   key, as requested by the project owner. Record results for the exact artifact.
2. Generate the release key interactively on an owner-controlled machine, using
   the agreed public identity and expiry. Enter the passphrase locally, never
   through chat or a committed environment file.
3. Keep the private key and revocation certificate outside the repository and
   downloaded release directories; maintain an offline backup and a key rotation/
   revocation plan. Export only the public verification key for users.
4. Record and independently publish the full trusted fingerprint. Select the
   signing key using `KILIMANJARO_GPG_KEY` and the existing `make release` hook.
   Confirm the signing environment has access to the intended key; do not place
   the secret key inside the container build image or ISO.
5. Verify detached signatures against the trusted fingerprint using a clean
   verification keyring. Verify SHA256SUMS against the exact ISO. Test that a
   modified ISO or manifest fails verification.
6. Publish the ISO, checksum manifest, their detached signatures, public key and
   fingerprint with verification instructions. Retain versioned release evidence.
7. Update website signing claims only after this verification workflow succeeds.
   The current website staging script intentionally does not infer authenticity
   from the mere presence of `.sig` files.

Secure Boot and GPG release signing are distinct. Signing a development ISO
does not make it production-ready or validate every driver/application inside it.

## Decisions and work still open

- Original code is GPL-3.0-only; documentation/artwork permissions remain to review.
- Third-party provenance and redistribution inventory/review.
- Required VM and physical hardware acceptance tests; update/recovery tests.
- Interactive key creation, key custody and trusted-fingerprint publication.
- End-to-end signature verification and website signed-release integration.
- The owner approved source publication to
  `https://github.com/Gerald-Poka/Kilimanjaro-Operating-System`.
  Source publication is not authorization to publish the ISO or claim stability.

Do not remove pending notices until their underlying tasks are complete.
