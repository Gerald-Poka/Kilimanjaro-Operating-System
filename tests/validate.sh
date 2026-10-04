#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
failures=0

python3 -B - <<'PY'
from pathlib import Path
import json
json.loads(Path("packaging/packages.json").read_text())
for parent in (Path("scripts"), Path("tests")):
    for source in parent.glob("*.py"):
        compile(source.read_text(), str(source), "exec")
print("PASS: packaging manifest and build/test Python syntax")
PY

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  failures=$((failures + 1))
}

pass() {
  printf 'PASS: %s\n' "$*"
}

if [[ -s "$ROOT_DIR/LICENSE" && -s "$ROOT_DIR/LICENSING.md" ]] && \
  grep -q 'GNU GENERAL PUBLIC LICENSE' "$ROOT_DIR/LICENSE" && \
  grep -q 'GPL-3.0-only' "$ROOT_DIR/LICENSING.md"; then
  pass 'GPL-3.0 license and original-code scope notice'
else
  fail 'GPL license or scope notice missing'
fi

# Debian 13 uses merged-/usr symlinks. Overlaying a directory at an alias can
# hide the installed system libraries; all such files must live under usr/.
for alias in bin sbin lib lib64; do
  [[ ! -d "$ROOT_DIR/overlay/$alias" ]] || fail "overlay/$alias must not replace a merged-/usr alias"
done

while IFS= read -r script; do
  if bash -n "$script"; then
    pass "bash syntax: ${script#"$ROOT_DIR/"}"
  else
    fail "bash syntax: ${script#"$ROOT_DIR/"}"
  fi
done < <(find \
  "$ROOT_DIR/scripts" \
  "$ROOT_DIR/tests" \
  "$ROOT_DIR/overlay/opt/kilimanjaro/bin" \
  -type f -name '*.sh' -print | sort)

for script in \
  overlay/opt/kilimanjaro/bin/kilimanjaro-firstboot \
  overlay/opt/kilimanjaro/bin/kilimanjaro-netmeter \
  overlay/opt/kilimanjaro/bin/kilimanjaro-software \
  overlay/usr/bin/kilimanjaro-welcome; do
  if bash -n "$ROOT_DIR/$script"; then
    pass "bash syntax: $script"
  else
    fail "bash syntax: $script"
  fi
done

if sh -n "$ROOT_DIR/overlay/usr/lib/live/config/0090-kilimanjaro-session"; then
  pass 'live Plasma X11 session override shell syntax'
else
  fail 'live Plasma X11 session override shell syntax'
fi

if python3 -B - overlay/opt/kilimanjaro/bin/kilimanjaro-network-monitor <<'PY'
import pathlib
import sys
source = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
compile(source, sys.argv[1], "exec")
PY
then
  pass 'Python syntax: overlay/opt/kilimanjaro/bin/kilimanjaro-network-monitor'
else
  fail 'Python syntax: overlay/opt/kilimanjaro/bin/kilimanjaro-network-monitor'
fi

if PYTHONPATH="$ROOT_DIR/overlay/opt/kilimanjaro/bin" python3 -B - <<'PY'
from netparse import parse_nethogs

rows = parse_nethogs("sshd/41/0\t2.50\t10.00\nchrome/52/1000\t0.25\t0.50\nheader\n")
assert rows == [
    ("sshd", 41, "0", 2.5, 10.0),
    ("chrome", 52, "1000", 0.25, 0.5),
]
assert parse_nethogs("Waiting for first packet\n") == []
PY
then
  pass 'NetHogs process-rate parser handles records and ignores status output'
else
  fail 'NetHogs process-rate parser test'
fi

while IFS= read -r json_file; do
  if python3 -m json.tool "$json_file" >/dev/null; then
    pass "JSON: ${json_file#"$ROOT_DIR/"}"
  else
    fail "invalid JSON: ${json_file#"$ROOT_DIR/"}"
  fi
done < <(find "$ROOT_DIR/overlay" -type f -name '*.json' -print | sort)

while IFS= read -r python_file; do
  if python3 -B - "$python_file" <<'PY'
import pathlib
import sys

source = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
compile(source, sys.argv[1], "exec")
PY
  then
    pass "Python syntax: ${python_file#"$ROOT_DIR/"}"
  else
    fail "Python syntax: ${python_file#"$ROOT_DIR/"}"
  fi
done < <(find "$ROOT_DIR/overlay" -type f -name '*.py' -print | sort)

policy_file="$ROOT_DIR/overlay/usr/share/polkit-1/actions/org.kilimanjaro.software.policy"
if python3 -B - "$policy_file" <<'PY'
import sys
import xml.etree.ElementTree as ET

ET.parse(sys.argv[1])
PY
then
  pass 'PolicyKit XML: overlay/usr/share/polkit-1/actions/org.kilimanjaro.software.policy'
else
  fail 'invalid PolicyKit policy XML'
fi

catalog_file="$ROOT_DIR/overlay/usr/share/kilimanjaro/software-catalog.json"
if python3 -B - "$catalog_file" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as source:
    catalog = json.load(source)

profile_ids = {item["id"] for item in catalog["profiles"]}
required = {"daily", "office", "development", "gaming", "creator", "communication", "ultimate"}
if profile_ids != required:
    raise SystemExit(f"profile IDs differ: {profile_ids ^ required}")

allowed_actions = {"helper", "url"}
if any(item["action"] not in allowed_actions for item in catalog["applications"]):
    raise SystemExit("unsupported application action")
PY
then
  pass 'software catalogue semantics'
else
  fail 'invalid software catalogue semantics'
fi

# shellcheck source=../config/build.env
source "$ROOT_DIR/config/build.env"

[[ "$DEBIAN_SUITE" == trixie ]] || fail 'Debian suite must be trixie for the v0.1 baseline'
[[ "$ARCH" == amd64 ]] || fail 'v0.1 supports amd64 only'
[[ "$ISO_LABEL" =~ ^[A-Z0-9_]{1,32}$ ]] || fail 'ISO label must be uppercase ASCII and at most 32 characters'
[[ "$DESKTOP_SESSION" == plasmax11 ]] || fail 'the current development baseline requires the tested Plasma X11 session'
[[ "$DISPLAY_MANAGER_SERVICE" == sddm.service ]] || fail 'the current design baseline requires SDDM'

for package_file in "$ROOT_DIR"/config/packages/*.list; do
  if awk 'NF && $1 !~ /^#/ && $1 !~ /^[a-z0-9][a-z0-9+.-]*$/ { exit 1 }' "$package_file"; then
    pass "package list format: ${package_file#"$ROOT_DIR/"}"
  else
    fail "package list format: ${package_file#"$ROOT_DIR/"}"
  fi
done

for profile_file in "$ROOT_DIR"/overlay/usr/share/kilimanjaro/profiles/*.list; do
  if awk 'NF && $1 !~ /^#/ && $1 !~ /^[a-z0-9][a-z0-9+.-]*(:[a-z0-9]+)?$/ { exit 1 }' "$profile_file"; then
    pass "profile package format: ${profile_file#"$ROOT_DIR/"}"
  else
    fail "profile package format: ${profile_file#"$ROOT_DIR/"}"
  fi
done

for required_path in \
  overlay/etc/systemd/system/kilimanjaro-firstboot.service \
  overlay/etc/systemd/system/kilimanjaro-netmeter.timer \
  overlay/etc/NetworkManager/conf.d/20-connectivity.conf \
  overlay/etc/firefox/policies/policies.json \
  overlay/etc/xdg/autostart/org.kilimanjaro.Welcome.desktop \
  overlay/etc/xdg/autostart/org.kilimanjaro.NetworkMonitor.desktop \
  overlay/etc/calamares/settings.conf \
  overlay/etc/calamares/modules/locale.conf \
  overlay/etc/calamares/branding/kilimanjaro/branding.desc \
  overlay/etc/calamares/branding/kilimanjaro/show.qml \
  overlay/usr/lib/live/config/0090-kilimanjaro-session \
  overlay/usr/share/applications/calamares-install-debian.desktop \
  overlay/usr/share/kio/servicemenus/kilimanjaro-open-konsole-here.desktop \
  overlay/opt/kilimanjaro/bin/kilimanjaro-software \
  overlay/opt/kilimanjaro/bin/kilimanjaro-network-monitor \
  overlay/opt/kilimanjaro/welcome/kilimanjaro_welcome.py \
  overlay/usr/share/applications/org.kilimanjaro.Welcome.desktop \
  overlay/usr/share/kilimanjaro/software-catalog.json \
  overlay/usr/share/kilimanjaro/about.json \
  overlay/usr/share/polkit-1/actions/org.kilimanjaro.software.policy; do
  [[ -f "$ROOT_DIR/$required_path" ]] || fail "missing required overlay: $required_path"
done

if python3 -B - "$ROOT_DIR/overlay/usr/share/kilimanjaro/about.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as source:
    about = json.load(source)
if about.get("author") != "Gerald Ndyamukama":
    raise SystemExit("creator attribution is missing")
if about.get("email") != "geraldndyamukama39@gmail.com":
    raise SystemExit("creator contact is missing")
if about.get("name") != "Kilimanjaro OS" or about.get("desktop") != "KDE Plasma":
    raise SystemExit("product identity is incomplete")
PY
then
  pass 'Kilimanjaro About metadata'
else
  fail 'invalid Kilimanjaro About metadata'
fi

for package in systemsettings kinfocenter pciutils pavucontrol timeshift cracklib-runtime wamerican; do
  if awk -v package="$package" '$1 == package { found = 1 } END { exit !found }' \
    "$ROOT_DIR/config/packages/desktop.list"; then
    pass "required system utility: $package"
  else
    fail "missing required system utility: $package"
  fi
done

# Capabilities the product documentation and the release gates depend on.
# Removing any of these silently breaks a promised feature.
for package in plasma-discover packagekit \
  cups cups-client cups-browsed cups-pk-helper foomatic-db-compressed-ppds \
  avahi-daemon \
  sane-utils orca kmag espeak-ng ibus plasma-nano libpam-kwallet-common \
  mesa-utils plasma-systemmonitor partitionmanager qemu-guest-agent \
  xserver-xorg-video-all xserver-xorg-input-all; do
  if awk -v package="$package" '$1 == package { found = 1 } END { exit !found }' \
    "$ROOT_DIR/config/packages/desktop.list"; then
    pass "required desktop capability: $package"
  else
    fail "missing required desktop capability: $package"
  fi
done

for package in fwupd smartmontools lm-sensors hdparm nvme-cli ethtool \
  network-manager-openvpn-gnome samba-common cifs-utils nfs-common \
  mobile-broadband-provider-info unattended-upgrades firmware-nvidia-gsp; do
  if awk -v package="$package" '$1 == package { found = 1 } END { exit !found }' \
    "$ROOT_DIR/config/packages/base.list"; then
    pass "required base capability: $package"
  else
    fail "missing required base capability: $package"
  fi
done

for package in hunspell-sw hunspell-en-gb p7zip-full unrar unar; do
  if awk -v package="$package" '$1 == package { found = 1 } END { exit !found }' \
    "$ROOT_DIR/config/packages/apps.list"; then
    pass "required application: $package"
  else
    fail "missing required application: $package"
  fi
done

# The three non-baseline pillars. Each list must exist, otherwise the glob in
# scripts/02-packages.sh silently stops shipping that pillar.
declare -A pillar_files=(
  [programming]="$ROOT_DIR/config/packages/development.list"
  [creator]="$ROOT_DIR/config/packages/creator.list"
  [gaming]="$ROOT_DIR/config/packages/gaming.list"
)
declare -A pillar_required=(
  [programming]="build-essential git pkg-config cmake ninja-build gdb python3-dev python3-pip python3-venv"
  [creator]="ffmpeg gimp inkscape krita kdenlive audacity blender fonts-noto-extra"
  [gaming]="steam wine wine32 gamemode mangohud nvidia-driver nvidia-settings"
)

for pillar in programming creator gaming; do
  manifest="${pillar_files[$pillar]}"
  if [[ -f "$manifest" ]]; then
    pass "$pillar pillar manifest exists: $(basename "$manifest")"
  else
    fail "$pillar pillar manifest is missing: $manifest"
    continue
  fi
  for package in ${pillar_required[$pillar]}; do
    if awk -v package="$package" '$1 == package { found = 1 } END { exit !found }' "$manifest"; then
      pass "$pillar pillar package: $package"
    else
      fail "missing $pillar pillar package: $package"
    fi
  done
done

# The package stage must discover every manifest by glob. A hardcoded list would
# let a newly added pillar file exist in the tree and never be installed.
if grep -Fq 'config/packages/*.list' "$ROOT_DIR/scripts/02-packages.sh" && \
   grep -Fq 'optional.list' "$ROOT_DIR/scripts/02-packages.sh"; then
  pass 'package stage loads all manifests by glob and skips optional.list'
else
  fail 'package stage must load manifests by glob while excluding optional.list'
fi

# Steam has no candidate without i386, so the multiarch step is load-bearing.
if grep -Fq 'dpkg --add-architecture i386' "$ROOT_DIR/scripts/02-packages.sh"; then
  pass 'i386 multiarch enabled for Steam and 32-bit Wine titles'
else
  fail 'i386 multiarch is not enabled; steam and wine32 cannot install'
fi

# DKMS module builds (notably NVIDIA) need headers matching the running kernel.
# --no-install-recommends omits them, so they must be declared explicitly.
for package in linux-headers-amd64 dkms; do
  if awk -v package="$package" '$1 == package { found = 1 } END { exit !found }' \
    "$ROOT_DIR/config/packages/base.list"; then
    pass "kernel build support: $package"
  else
    fail "missing kernel build support: $package"
  fi
done

# The kernel and the headers metapackage must both resolve from the stable
# suite. Any pin that lifts the kernel or headers above stable would pair the
# kernel with headers from a different series and break every DKMS build.
if grep -Eq 'Pin-Priority: (9[0-9][0-9]|[1-9][0-9]{3,})' "$ROOT_DIR/scripts/02-packages.sh"; then
  fail '02-packages.sh raises a package above stable; the kernel and headers must not be pinned to another series'
else
  pass 'kernel and headers are not pinned above the stable suite'
fi

# Packages that were removed on purpose. Their presence would contradict the
# documented reasoning and reintroduce dead weight or a false impression of
# capability.
for package in clamav clamav-daemon; do
  if awk -v package="$package" '$1 == package { found = 1 } END { exit !found }' \
    "$ROOT_DIR"/config/packages/*.list; then
    fail "package was removed deliberately but is still declared: $package"
  else
    pass "correctly absent: $package"
  fi
done

# Packages that cannot be installed unattended must never reach an image list.
for package in ttf-mscorefonts-installer tlp zram-tools libdvdcss2; do
  if awk -v package="$package" '$1 == package { found = 1 } END { exit !found }' \
    "$ROOT_DIR"/config/packages/*.list; then
    fail "package requires manual acceptance and must stay out of the image: $package"
  else
    pass "correctly absent: $package"
  fi
done

if grep -Eq '^MimeType=inode/directory;$' \
    "$ROOT_DIR/overlay/usr/share/kio/servicemenus/kilimanjaro-open-konsole-here.desktop" && \
   grep -Eq '^Exec=konsole --workdir ' \
    "$ROOT_DIR/overlay/usr/share/kio/servicemenus/kilimanjaro-open-konsole-here.desktop"; then
  pass 'Dolphin folder context menu opens Konsole in the selected directory'
else
  fail 'Konsole folder context menu action is incomplete'
fi

for package in calamares calamares-settings-debian; do
  if awk -v package="$package" '$1 == package { found = 1 } END { exit !found }' \
    "$ROOT_DIR/config/packages/desktop.list"; then
    pass "installer package: $package"
  else
    fail "missing installer package: $package"
  fi
done

if grep -Eq '^branding:[[:space:]]+kilimanjaro$' "$ROOT_DIR/overlay/etc/calamares/settings.conf" && \
   grep -Eq '^prompt-install:[[:space:]]+true$' "$ROOT_DIR/overlay/etc/calamares/settings.conf" && \
   grep -Eq '^[[:space:]]+- partition$' "$ROOT_DIR/overlay/etc/calamares/settings.conf" && \
   grep -Eq '^[[:space:]]+- bootloader$' "$ROOT_DIR/overlay/etc/calamares/settings.conf"; then
  pass 'Calamares uses Kilimanjaro branding and an explicit install confirmation'
else
  fail 'Calamares settings are missing required identity or safety settings'
fi

for design_asset in \
  overlay/usr/share/wallpapers/Kilimanjaro/contents/images/3840x2160.png \
  overlay/usr/share/wallpapers/Kilimanjaro-Dawn/contents/images/3840x2160.png \
  overlay/usr/share/wallpapers/Kilimanjaro-Blue-Hour/contents/images/3840x2160.png \
  overlay/usr/share/wallpapers/Kilimanjaro-Green-Morning/contents/images/3840x2160.png \
  overlay/usr/share/wallpapers/Kilimanjaro-Uhuru-Glacier/contents/images/3840x2160.png \
  overlay/usr/share/wallpapers/Kilimanjaro-Savanna-Gold/contents/images/3840x2160.png \
  overlay/usr/share/pixmaps/kilimanjaro-logo.png \
  overlay/usr/share/color-schemes/KilimanjaroDark.colors \
  overlay/usr/share/plasma/look-and-feel/org.kilimanjaro.desktop/metadata.json \
  overlay/usr/share/plymouth/themes/kilimanjaro/kilimanjaro.plymouth; do
  [[ -f "$ROOT_DIR/$design_asset" ]] || fail "missing design asset: $design_asset"
done

if python3 -B - "$ROOT_DIR/overlay/usr/share/wallpapers" <<'PY'
import json
import pathlib
import struct
import sys

root = pathlib.Path(sys.argv[1])
expected = {
    "Kilimanjaro": ("Kilimanjaro", "Kilimanjaro Sunset"),
    "Kilimanjaro-Dawn": ("KilimanjaroDawn", "Kilimanjaro Dawn"),
    "Kilimanjaro-Blue-Hour": ("KilimanjaroBlueHour", "Kilimanjaro Blue Hour"),
    "Kilimanjaro-Green-Morning": ("KilimanjaroGreenMorning", "Kilimanjaro Green Morning"),
    "Kilimanjaro-Uhuru-Glacier": ("KilimanjaroUhuruGlacier", "Kilimanjaro Uhuru Glacier"),
    "Kilimanjaro-Savanna-Gold": ("KilimanjaroSavannaGold", "Kilimanjaro Savanna Gold"),
    "Kilimanjaro-Moonlight": ("KilimanjaroMoonlight", "Kilimanjaro Moonlight"),
    "Kilimanjaro-Forest-Mist": ("KilimanjaroForestMist", "Kilimanjaro Forest Mist"),
    "Kilimanjaro-Sea-of-Clouds": ("KilimanjaroSeaofClouds", "Kilimanjaro Sea of Clouds"),
    "Kilimanjaro-Amber-Highlands": ("KilimanjaroAmberHighlands", "Kilimanjaro Amber Highlands"),
    "Kilimanjaro-Violet-Twilight": ("KilimanjaroVioletTwilight", "Kilimanjaro Violet Twilight"),
}
for package, (plugin_id, name) in expected.items():
    directory = root / package
    metadata = json.loads((directory / "metadata.json").read_text(encoding="utf-8"))["KPlugin"]
    if metadata.get("Id") != plugin_id or metadata.get("Name") != name:
        raise SystemExit(f"bad wallpaper metadata in {package}")
    image = directory / "contents/images/3840x2160.png"
    header = image.read_bytes()[:24]
    if header[:8] != b"\x89PNG\r\n\x1a\n":
        raise SystemExit(f"not a PNG wallpaper: {image}")
    width, height = struct.unpack(">II", header[16:24])
    expected_size = (1672, 941) if package == "Kilimanjaro" else (3840, 2160)
    if (width, height) != expected_size:
        raise SystemExit(f"unexpected wallpaper size in {image}: {width}x{height}")
PY
then
  pass 'eleven distinct Kilimanjaro wallpaper entries (ten 3840x2160 alternates)'
else
  fail 'Kilimanjaro wallpaper entries are incomplete or malformed'
fi

# Generated bytecode must never be committed; it is interpreter-specific and
# would be copied into the image by the overlay sync.
if find "$ROOT_DIR/overlay" \( -name '__pycache__' -o -name '*.pyc' \) -print -quit | grep -q .; then
  fail 'overlay contains generated Python bytecode (__pycache__ or .pyc)'
else
  pass 'overlay is free of generated Python bytecode'
fi

preset="$ROOT_DIR/overlay/etc/systemd/system-preset/90-kilimanjaro.preset"
if grep -Eq '^enable cups\.service$' "$preset" && \
   grep -Eq '^enable cups-browsed\.service$' "$preset" && \
   grep -Eq '^disable ssh\.service$' "$preset" && \
   ! grep -Eq '^[[:space:]]*(enable|disable|mask)[[:space:]]+clamav' "$preset"; then
  pass 'systemd preset enables printing and keeps remote access off by default'
else
  fail 'systemd preset does not match the documented service policy'
fi

auto_upgrades="$ROOT_DIR/overlay/etc/apt/apt.conf.d/20auto-upgrades"
unattended="$ROOT_DIR/overlay/etc/apt/apt.conf.d/51-kilimanjaro-unattended-upgrades"
if grep -Eq '^APT::Periodic::Unattended-Upgrade "0";$' "$auto_upgrades" && \
   grep -Eq '^APT::Periodic::Enable "0";$' "$auto_upgrades" && \
   [[ -f "$unattended" ]] && \
   grep -Eq 'distro_codename\}-security' "$unattended" && \
   grep -Eq '^Unattended-Upgrade::Automatic-Reboot "false";$' "$unattended"; then
  pass 'updates stay opt-in while unattended-upgrades is scoped to security archives'
else
  fail 'unattended-upgrades policy is missing, unbounded, or set to run automatically'
fi

# The archive channel is either fully disabled or fully configured. A URL
# without a matching key and fingerprint must never produce an image.
repo_vars=$(awk -F= '/^KILIMANJARO_APT_REPO_(URL|FINGERPRINT|KEY)=/ {
  value = $0; sub(/^[^=]*=/, "", value); gsub(/"/, "", value)
  print $1 "=" (length(value) ? "set" : "empty")
}' "$ROOT_DIR/config/build.env")
repo_url=$(printf '%s\n' "$repo_vars" | awk -F= '$1 == "KILIMANJARO_APT_REPO_URL" {print $2}')
repo_fpr=$(printf '%s\n' "$repo_vars" | awk -F= '$1 == "KILIMANJARO_APT_REPO_FINGERPRINT" {print $2}')
repo_key=$(printf '%s\n' "$repo_vars" | awk -F= '$1 == "KILIMANJARO_APT_REPO_KEY" {print $2}')
if [[ "$repo_url" == empty && "$repo_fpr" == empty && "$repo_key" == empty ]]; then
  pass 'archive update channel is inactive by default'
elif [[ "$repo_url" == set && "$repo_fpr" == set && "$repo_key" == set ]]; then
  pass 'archive update channel is fully configured (URL, fingerprint and key)'
else
  fail 'archive update channel is partially configured; set all three variables or none'
fi

# The archive suite is hardcoded, so it must track the codename.
if grep -Fq "Suites: $OS_VERSION_CODENAME" "$ROOT_DIR/scripts/configure-apt-source.py"; then
  pass 'archive suite matches OS_VERSION_CODENAME'
else
  fail 'archive suite in configure-apt-source.py does not match OS_VERSION_CODENAME'
fi

# The kernel comes from the stable suite, not backports. Backports stays
# configured at low priority purely so installed systems can opt into single
# packages with -t.
if [[ "$DEBIAN_BACKPORTS_SUITE" == "${DEBIAN_SUITE}-backports" ]]; then
  pass 'backports suite is derived from the stable suite'
else
  fail 'backports suite must be derived from DEBIAN_SUITE'
fi

if [[ "$DEBIAN_BACKPORTS_SUITE" != *-sid* && "$DEBIAN_BACKPORTS_SUITE" != *unstable* ]]; then
  pass 'unstable suites are never configured'
else
  fail 'an unstable suite must never be configured as a source'
fi

# 6.12 is the newest kernel series the packaged proprietary NVIDIA driver builds
# against. No NVIDIA driver in stable, backports or sid supports 7.x, so a
# minimum of 7 would guarantee an unbootable NVIDIA image.
if [[ "$KILIMANJARO_KERNEL_MIN_MAJOR" =~ ^[0-9]+$ ]] && (( KILIMANJARO_KERNEL_MIN_MAJOR >= 6 && KILIMANJARO_KERNEL_MIN_MAJOR <= 6 )); then
  pass 'build targets the 6.x kernel series, which the packaged NVIDIA driver supports'
else
  fail 'KILIMANJARO_KERNEL_MIN_MAJOR must be 6; no packaged NVIDIA driver builds against 7.x'
fi

packages_script="$ROOT_DIR/scripts/02-packages.sh"
if grep -Fq '$DEBIAN_BACKPORTS_SUITE main contrib non-free non-free-firmware' "$packages_script" && \
   grep -Fq 'APT::Default-Release "$DEBIAN_SUITE"' "$packages_script" && \
   grep -Fq '50-kilimanjaro-backports' "$packages_script"; then
  pass 'package stage adds backports and pins the default release to stable'
else
  fail 'package stage does not configure the backports source and stable default release'
fi

image_script="$ROOT_DIR/scripts/04-image.sh"
if grep -Fq 'kernel_major < KILIMANJARO_KERNEL_MIN_MAJOR' "$image_script"; then
  pass 'image stage refuses to ship a kernel older than the required major'
else
  fail 'image stage does not enforce the minimum kernel major'
fi

if [[ "$failures" -eq 0 ]]; then
  printf '\nAll validations passed.\n'
else
  printf '\n%d validation(s) failed.\n' "$failures" >&2
  exit 1
fi
