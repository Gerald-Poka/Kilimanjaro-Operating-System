"""Parser for NetHogs trace-mode process rate records."""

import re

ROW = re.compile(r"^(.+?)/(\d+)/(\d+)\s+([\d.]+)\s+([\d.]+)\s*$")


def parse_nethogs(text: str) -> list[tuple[str, int, str, float, float]]:
    """Parse NetHogs trace rows (program/PID/UID, sent, received in kB/s)."""
    rows = {}
    for line in text.splitlines():
        match = ROW.match(line.strip())
        if not match:
            continue
        name, pid, uid, sent, received = match.groups()
        rows[(int(pid), name)] = (name, int(pid), uid, float(sent), float(received))
    return sorted(rows.values(), key=lambda row: row[3] + row[4], reverse=True)
