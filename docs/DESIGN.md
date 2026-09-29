# Kilimanjaro OS design system

Kilimanjaro OS uses a custom KDE Plasma 6 presentation built entirely on Debian stable packages. It borrows the confident, polished density of a modern Nobara KDE desktop and a smaller amount of Ubuntu's warmth and accessibility, while retaining an original identity.

## Design principles

1. **Reliable before decorative.** Breeze components and Debian packages provide the behavioral foundation. Kilimanjaro changes configuration, palette, layout, and artwork instead of carrying a forked widget toolkit.
2. **Recognizable at a glance.** The mountain, dawn light, volcanic charcoal, and turquoise accent make the system distinct without copying another distribution's marks.
3. **Comfortable for long sessions.** Dark neutral surfaces avoid pure black, text contrast remains high, animation is slightly shortened, and focus states use a visible warm accent.
4. **Usable offline.** The desktop does not depend on downloading a theme, wallpaper, icon pack, or web asset after installation.
5. **Easy to repair.** Removing a user configuration restores standard Plasma behavior; system components remain upstream packages.

## Visual tokens

| Role | Value |
|---|---|
| Volcanic background | `#12141A` |
| Window surface | `#1A1D25` |
| Elevated surface | `#22262F` |
| Primary text | `#EFF1F5` |
| Snow ivory | `#F3F1E8` |
| Dawn amber | `#F59E42` |
| Turquoise success/accent | `#20B8A6` |
| Error | `#EF5350` |

Inter is the interface typeface, Hack is used for terminals and fixed-width text, Papirus supplies application icons, and the custom Kilimanjaro icon replaces the distribution launcher mark.

## Desktop composition

- A single 52-pixel floating bottom panel keeps the layout familiar and dependable.
- The launcher sits at the left, followed by pinned file manager, browser, office, and terminal applications.
- Status indicators, clock, and Show Desktop stay together at the right.
- Two virtual desktops are available by default.
- Double-click opens files, reducing accidental launches for new desktop users.
- Plasma effects remain enabled but use shorter animation timing.

## Branded surfaces

- GRUB live-boot menu
- Plymouth startup splash
- SDDM login screen
- Plasma startup splash
- Plasma desktop and lock screen
- Application launcher icon
- KDE/Qt application color scheme and fonts

## Source locations

```text
overlay/usr/share/wallpapers/Kilimanjaro/
overlay/usr/share/pixmaps/kilimanjaro-logo.png
overlay/usr/share/color-schemes/KilimanjaroDark.colors
overlay/usr/share/icons/Kilimanjaro/
overlay/usr/share/plasma/look-and-feel/org.kilimanjaro.desktop/
overlay/usr/share/plymouth/themes/kilimanjaro/
overlay/etc/sddm.conf.d/
overlay/etc/skel/.config/
```

New design work should preserve the palette and behavioral principles above. Any new effect or third-party theme must have a clear maintenance owner and a tested fallback before it enters a release image.
