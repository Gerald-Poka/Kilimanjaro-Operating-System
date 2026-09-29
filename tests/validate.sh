#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
failures=0

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

if python3 - overlay/opt/kilimanjaro/bin/kilimanjaro-network-monitor <<'PY'
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

if PYTHONPATH="$ROOT_DIR/overlay/opt/kilimanjaro/bin" python3 - <<'PY'
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
  if python3 - "$python_file" <<'PY'
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
if python3 - "$policy_file" <<'PY'
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
if python3 - "$catalog_file" <<'PY'
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

if python3 - "$ROOT_DIR/overlay/usr/share/kilimanjaro/about.json" <<'PY'
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

for package in systemsettings kinfocenter pciutils pavucontrol timeshift nvidia-settings cracklib-runtime wamerican; do
  if awk -v package="$package" '$1 == package { found = 1 } END { exit !found }' \
    "$ROOT_DIR/config/packages/desktop.list"; then
    pass "required system utility: $package"
  else
    fail "missing required system utility: $package"
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

if python3 - "$ROOT_DIR/overlay/usr/share/wallpapers" <<'PY'
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
  pass 'six distinct Kilimanjaro wallpaper entries (five 4K alternates)'
else
  fail 'Kilimanjaro wallpaper entries are incomplete or malformed'
fi

if [[ "$failures" -eq 0 ]]; then
  printf '\nAll validations passed.\n'
else
  printf '\n%d validation(s) failed.\n' "$failures" >&2
  exit 1
fi
