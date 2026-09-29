# Kilimanjaro OS website

React + Vite, with plain CSS and no external font, analytics or runtime CDN dependency. Existing OS wallpapers and emblem are reused; wallpaper WebP copies are optimized for the web without changing the original OS artwork.

## Run locally

Requires Node 22.12+ and ImageMagick (`magick`) for asset preparation.

```bash
cd website
npm ci
npm run assets
npm run dev
```

Open the local address printed by Vite. The default binds to localhost only.

## Structure

```text
src/pages/         One file per routed page, plus a not-found page
src/sections/      One file per content section (hero, gallery, software, FAQ, etc.)
src/components/    Shared header, footer, icons and cursor field
src/layouts/       Shared page shell, titles, focus and scroll reset
src/data/          Editable feature, application and FAQ content
src/hooks/         Reduced-motion preference
src/styles/        Tokens, global layout, component/responsive styles
public/brand/      Existing Kilimanjaro emblem
public/wallpapers/ Six optimized OS wallpapers
scripts/           Asset preparation and development-release staging
tests/             Desktop/mobile browser tests
```

The hero rotates through six scenes every ten seconds. Its mountain-ridgeline constellation responds to the pointer on fine-pointer devices. The pause button stops both effects. Reduced-motion preference disables automatic motion, while manual wallpaper selection remains available. Animation stops when the hero is offscreen or the tab is hidden.

## Readable typography

The site uses a standard system sans-serif stack, a `1rem` body size (normally
16px), and a `0.875rem` minimum for labels and fine print (normally 14px).
Footer reading text is 16px-equivalent, with 14px-equivalent copyright text and
brighter colors. These are project design choices, not a WCAG-mandated minimum
font size. Layouts wrap and expand rather than shrinking text. Browser tests
check minimum computed sizes across all pages, narrow-screen overflow, enlarged
root text, and footer color contrast. This is not a full accessibility audit.

## Separate pages

Navigation uses React Router, not scroll anchors. Each route renders only its
own page inside the shared header/footer:

- `/` — Home
- `/why-kilimanjaro` — Why Kilimanjaro
- `/explore` — Application explorer
- `/desktop` — Wallpaper collection
- `/downloads` — Development ISO and verification information
- `/getting-started` — Installation steps and FAQ (separate section files)
- `/about` — Project background and author
- `/documentation` — Full development-build user guide, with one file per guide section
- `/legal` — Warranty/support, risk, licenses, independence and privacy notices
- `/release-status` — Passed virtual boot checks and six remaining release gates

Browser back/forward works, the current navigation item is highlighted, and
each page has its own document title. Unknown paths show a not-found page.

## User documentation and legal notices

Documentation covers download/checksum verification, VM preparation, Calamares
installation, installed-disk reboot checks, first boot, software profiles,
manual updates, backup/recovery precautions and troubleshooting/support.
`src/sections/documentation/` contains a separate file for each topic; the
contents list is in `src/data/documentation.js`. Getting started remains a short
guide and links to the full documentation. The header and footer expose the
documentation; the footer and guides expose the separate legal page.

The guide describes the current 0.1.0 development artifact, not a qualified
stable release. Physical USB installs, dual boot, encryption, hardware drivers
and recovery are explicitly not represented as tested. Firmware boot-chain
signing and release GPG authentication are explained separately. Keep the
date, limitations and acceptance evidence synchronized with each release.

The legal sections are plain-language project notices, not a finalized EULA or
legal advice. Original project code is now GPL-3.0-only. They preserve upstream author credits and individual package
licenses, reference Debian's official license/disclaimer information, and do
not claim Fedora/RPMFusion sources. Artwork/documentation licensing and
third-party provenance still need review; obtain
appropriate redistribution/legal/privacy review before public release.

## Development download preview

```bash
npm run stage:release
```

This verifies the existing ISO against `../output/SHA256SUMS` before copying it and the manifest into `public/releases/`. It enables the real **development** download locally. A filesystem reflink is requested where supported; otherwise the ISO is copied (size varies with selected packages). Generated release files are ignored by Git.

No release staged means the download button is disabled. There is no invented public URL, signing key, release signature, stable edition, support promise or community link. The staging script does not authenticate signatures; the UI currently states release GPG signing is pending even if signature files exist. Establish a trusted fingerprint and verified signing workflow before changing that claim.

## Build and test

```bash
npx playwright install chromium
npm test
npm run build
npm run preview
```

Browser tests cover desktop/mobile overflow, navigation, scene controls, filtering, FAQ, reduced motion, un-staged downloads, console errors and staged-download headers. Screenshots are written to `test-results/` for visual inspection.

Deploy `dist/` to a static host only after approving the release content. A staged ISO is copied into `dist/` by the build and significantly increases its size; unstaged builds contain only the website. Production should serve ISO artifacts from a suitable download host and update the download component/content accordingly. Domain registration, hosting and public publishing have not been performed.

The host must serve `index.html` for client-side routes so direct links and
refreshes work. `public/_redirects` supplies the fallback for hosts supporting
that convention. For nginx, use `try_files $uri $uri/ /index.html;` in the site
location block. Existing assets and release downloads must be served normally,
not replaced by the fallback. Vite's development/preview servers already handle
these routes.

## Content sources and status

Purpose, bando preservation, education, offline-first scope and localization direction come from `Kilimanjaro-OS-Blueprint.docx` (September 2026, sections 1, 7, 8, 10 and 13). Current implementation facts come from the project README, package manifests, Welcome catalog and actual VM test evidence. The blueprint's XFCE proposal is superseded by the user's KDE direction and current implementation. Goals such as complete translation, ROG support and signed offline update bundles are not presented as completed features.

Project author/contact: Gerald Ndyamukama, geraldndyamukama39@gmail.com. Third-party software retains its original credits. No logos or artwork from the Nobara/Kali website references were copied.
