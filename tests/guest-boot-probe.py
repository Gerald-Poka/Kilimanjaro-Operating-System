#!/usr/bin/env python3
"""Verify desktop readiness through a disposable live VM's serial console."""
import socket
import sys
import time

serial_path, username, timeout = sys.argv[1:4]
secureboot = len(sys.argv) > 4 and sys.argv[4] == 'secureboot'
deadline = time.monotonic() + int(timeout)
sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
sock.settimeout(0.5)
while time.monotonic() < deadline:
    try:
        sock.connect(serial_path)
        break
    except (FileNotFoundError, ConnectionRefusedError):
        time.sleep(0.2)
else:
    raise SystemExit('FAIL: VM serial console unavailable')

buffer = ''
logged_in = False
next_probe = time.monotonic() + 10
last_login = 0
while time.monotonic() < deadline:
    try:
        data = sock.recv(65536)
        if not data:
            raise SystemExit('FAIL: VM serial console closed')
        buffer = (buffer + data.decode(errors='replace'))[-16384:]
        if 'login:' in buffer and time.monotonic() - last_login > 5:
            sock.sendall((username + '\n').encode())
            last_login = time.monotonic()
            buffer = ''
        elif 'Password:' in buffer:
            # Debian live-config's public live-media password, never shipped
            # as an installed-system credential.
            sock.sendall(b'live\n')
            buffer = ''
        elif f'{username}@' in buffer and '$' in buffer:
            logged_in = True
        if 'KILI_BOOT_OK' in buffer:
            print('PASS: guest confirms graphical.target, SDDM and Plasma are running')
            if secureboot:
                print('PASS: guest confirms SecureBoot enabled')
            sys.exit(0)
    except socket.timeout:
        pass
    if logged_in and time.monotonic() >= next_probe:
        command = (
            b"systemctl is-active --quiet sddm.service && "
            b"systemctl is-active --quiet graphical.target && "
            b"pgrep -x plasmashell >/dev/null && printf '\\nKILI_%s_%s\\n' BOOT OK\n"
        )
        if secureboot:
            command = b"mokutil --sb-state | grep -q 'SecureBoot enabled' && " + command
        sock.sendall(command)
        next_probe = time.monotonic() + 8
raise SystemExit('FAIL: guest desktop did not become ready within the timeout')
