# Kilimanjaro licensing scope

Copyright (C) 2026 Gerald Ndyamukama.

Original Kilimanjaro program code is licensed under the GNU General Public
License version 3 only (`GPL-3.0-only`). You may redistribute and modify that
code under those terms. It is provided without warranty, to the extent permitted
by applicable law. The complete license text is in [LICENSE](LICENSE).

This applies to original project build scripts, tests, website code and
Kilimanjaro-authored application/configuration code, unless a file already
declares a different license or incorporates upstream work under its own terms.
It does not claim ownership of, or relicense, third-party code.

## Separate components and assets

- Debian/Linux/KDE/Calamares and other installed packages retain their own
  licenses, copyrights and attribution. Their packages are not made GPL-3.0-only
  simply because Kilimanjaro distributes an OS image containing them.
- Dependencies installed by npm, APT, Flatpak or vendor installers remain subject
  to their individual licenses. Preserve their notices and comply with applicable
  source/distribution requirements.
- Existing theme metadata declaring GPL-3.0-or-later and wallpaper metadata
  declaring CC-BY-SA-4.0 are not overridden by this code license. Artwork origins,
  attribution and redistribution permissions still need to be inventoried before
  public distribution. Other artwork, branding, documentation and supplied
  blueprints are not automatically relicensed by the original-code choice.
- Upstream-derived files must retain their original license/credits; unresolved
  provenance must be reviewed before publication. The project author is not the
  author of every upstream application.

For installed Debian packages, inspect `/usr/share/doc/<package>/copyright`.
Public ISO distribution requires satisfying the obligations for every included
component, including corresponding-source requirements where applicable. See
[publication readiness](docs/PUBLISHING.md).
