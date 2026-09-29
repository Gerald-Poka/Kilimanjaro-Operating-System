#!/usr/bin/env python3
"""Kilimanjaro Welcome: first-run setup and curated software profiles."""

from __future__ import annotations

import argparse
import json
import os
import platform
import shutil
import subprocess
import sys
from pathlib import Path

from PyQt6.QtCore import QProcess, QSize, Qt, QUrl, pyqtSignal
from PyQt6.QtGui import QDesktopServices, QIcon, QPixmap, QTextCursor
from PyQt6.QtWidgets import (
    QApplication,
    QCheckBox,
    QDialog,
    QFrame,
    QGridLayout,
    QHBoxLayout,
    QLabel,
    QMainWindow,
    QMessageBox,
    QPlainTextEdit,
    QProgressBar,
    QPushButton,
    QScrollArea,
    QSizePolicy,
    QStackedWidget,
    QVBoxLayout,
    QWidget,
)


CATALOG_PATH = Path("/usr/share/kilimanjaro/software-catalog.json")
ABOUT_PATH = Path("/usr/share/kilimanjaro/about.json")
HELPER_PATH = "/opt/kilimanjaro/bin/kilimanjaro-software"
LOGO_PATH = Path("/usr/share/pixmaps/kilimanjaro-logo.png")
STATE_PATH = Path.home() / ".config" / "kilimanjaro" / "welcome-complete"


STYLE = """
* {
    font-family: "Inter", "Noto Sans", sans-serif;
    color: #F4F7FA;
}
QMainWindow, QWidget#Root { background: #11171C; }
QFrame#Sidebar {
    background: #0B1014;
    border-right: 1px solid #26323A;
}
QLabel#Brand { font-size: 20px; font-weight: 700; }
QLabel#Edition { color: #92A2AD; font-size: 11px; letter-spacing: 1px; }
QPushButton[nav="true"] {
    background: transparent;
    border: 0;
    border-radius: 10px;
    padding: 12px 15px;
    text-align: left;
    color: #AEBBC4;
    font-size: 14px;
}
QPushButton[nav="true"]:hover { background: #172127; color: white; }
QPushButton[nav="true"][active="true"] {
    background: #243037;
    color: #F8B84E;
    border-left: 3px solid #F59E0B;
}
QFrame#Hero {
    background: qlineargradient(x1:0,y1:0,x2:1,y2:1,
        stop:0 #202B32, stop:0.55 #172127, stop:1 #2A2118);
    border: 1px solid #33414A;
    border-radius: 22px;
}
QLabel#Eyebrow { color: #F8B84E; font-weight: 700; letter-spacing: 1px; }
QLabel#HeroTitle { font-size: 34px; font-weight: 750; }
QLabel#HeroBody { color: #BAC6CD; font-size: 15px; }
QLabel#PageTitle { font-size: 27px; font-weight: 700; }
QLabel#PageBody { color: #98A8B2; font-size: 14px; }
QFrame#Card {
    background: #182127;
    border: 1px solid #2B3840;
    border-radius: 16px;
}
QFrame#Card:hover { border-color: #4A5D68; background: #1B262D; }
QLabel#CardTitle { font-size: 17px; font-weight: 650; }
QLabel#CardSubtitle { color: #F8B84E; font-size: 12px; font-weight: 600; }
QLabel#Muted { color: #98A8B2; }
QLabel#Badge {
    background: #26343B;
    color: #BDD0D8;
    border-radius: 8px;
    padding: 4px 8px;
    font-size: 11px;
}
QFrame#Notice {
    background: #2A2317;
    border: 1px solid #664A1C;
    border-radius: 12px;
}
QFrame#GoodNotice {
    background: #142925;
    border: 1px solid #235E53;
    border-radius: 12px;
}
QPushButton#Primary {
    background: #F59E0B;
    color: #17120A;
    border: 0;
    border-radius: 10px;
    padding: 10px 17px;
    font-weight: 700;
}
QPushButton#Primary:hover { background: #FBBF24; }
QPushButton#Secondary {
    background: #26343B;
    color: #F4F7FA;
    border: 1px solid #3B4B54;
    border-radius: 10px;
    padding: 9px 16px;
    font-weight: 600;
}
QPushButton#Secondary:hover { background: #32434C; border-color: #607783; }
QPushButton:disabled { color: #75838B; background: #222B30; }
QScrollArea { border: 0; background: transparent; }
QScrollArea > QWidget > QWidget { background: transparent; }
QPlainTextEdit {
    background: #0A0F12;
    color: #C7D4DB;
    border: 1px solid #2D3B43;
    border-radius: 9px;
    font-family: "Hack", monospace;
    padding: 8px;
}
QProgressBar {
    background: #253038;
    border: 0;
    border-radius: 4px;
    height: 8px;
}
QProgressBar::chunk { background: #F59E0B; border-radius: 4px; }
QCheckBox { color: #AEBBC4; spacing: 9px; }
"""


def load_catalog() -> dict:
    with CATALOG_PATH.open(encoding="utf-8") as catalog_file:
        return json.load(catalog_file)


def load_about() -> dict:
    try:
        with ABOUT_PATH.open(encoding="utf-8") as about_file:
            return json.load(about_file)
    except (OSError, json.JSONDecodeError):
        return {
            "name": "Kilimanjaro OS",
            "version": "0.1.0",
            "codename": "Uhuru",
            "author": "Gerald Ndyamukama",
            "email": "geraldndyamukama39@gmail.com",
            "based_on": "Debian GNU/Linux 13 (Trixie)",
            "desktop": "KDE Plasma",
            "purpose": "A complete operating system for work, development, gaming, and creativity.",
        }


def command_output(command: list[str], fallback: str = "Unavailable") -> str:
    try:
        result = subprocess.run(
            command,
            check=False,
            capture_output=True,
            text=True,
            timeout=3,
        )
        value = result.stdout.strip()
        return value if value else fallback
    except (OSError, subprocess.TimeoutExpired):
        return fallback


def is_live_session() -> bool:
    try:
        cmdline = Path("/proc/cmdline").read_text(encoding="utf-8")
    except OSError:
        cmdline = ""
    return "boot=live" in cmdline or Path("/run/live/medium").exists()


def hardware_summary() -> dict[str, str]:
    cpu = platform.processor() or command_output(["lscpu", "-J"], platform.machine())
    try:
        for line in Path("/proc/cpuinfo").read_text(encoding="utf-8").splitlines():
            if line.lower().startswith("model name"):
                cpu = line.split(":", 1)[1].strip()
                break
    except OSError:
        pass

    memory = "Unavailable"
    try:
        for line in Path("/proc/meminfo").read_text(encoding="utf-8").splitlines():
            if line.startswith("MemTotal:"):
                kib = int(line.split()[1])
                memory = f"{kib / 1024 / 1024:.1f} GiB"
                break
    except (OSError, ValueError, IndexError):
        pass

    virtualizer = command_output(["systemd-detect-virt", "--vm"], "none").strip().lower()
    is_virtual = virtualizer not in {"", "none"}
    pci_devices = command_output(["lspci"], "")
    gpu_lines = [
        line
        for line in pci_devices.splitlines()
        if "VGA compatible controller" in line or "3D controller" in line
    ]
    if gpu_lines:
        gpu = "; ".join(line.split(": ", 1)[-1] for line in gpu_lines)
        if is_virtual:
            gpu += "; host graphics hardware is not passed through to this VM"
    elif is_virtual:
        gpu = "Virtual display adapter; host GPU passthrough is not enabled"
    else:
        gpu = "No graphics adapter was reported by the system"
    network = command_output(["nmcli", "-t", "-f", "STATE", "general"], "Unknown")
    session = os.environ.get("XDG_SESSION_TYPE", "Unknown").upper()
    firmware = "UEFI" if Path("/sys/firmware/efi").exists() else "Legacy BIOS"
    if is_virtual:
        firmware = f"{firmware} (virtual machine)"
    details = {
        "Processor": cpu,
        "Memory": f"{memory} available to this VM" if is_virtual else memory,
        "Graphics": gpu,
        "Network": network.capitalize(),
        "Session": session,
        "Boot firmware": firmware,
    }
    if is_virtual:
        details = {"Environment": f"Virtual machine ({virtualizer})", **details}
    return details


def themed_icon(name: str, fallback: str = "applications-other") -> QIcon:
    icon = QIcon.fromTheme(name)
    return icon if not icon.isNull() else QIcon.fromTheme(fallback)


class InstallDialog(QDialog):
    def __init__(self, target: str, title: str, parent: QWidget | None = None) -> None:
        super().__init__(parent)
        self.target = target
        self.setWindowTitle(f"Install {title}")
        self.setMinimumSize(720, 460)
        self.setModal(True)

        layout = QVBoxLayout(self)
        layout.setContentsMargins(22, 22, 22, 22)
        layout.setSpacing(14)

        heading = QLabel(f"Installing {title}")
        heading.setObjectName("PageTitle")
        layout.addWidget(heading)

        explanation = QLabel(
            "The system will request your administrator password. Packages are "
            "downloaded from configured Debian, Flathub, or signed vendor sources."
        )
        explanation.setObjectName("PageBody")
        explanation.setWordWrap(True)
        layout.addWidget(explanation)

        self.progress = QProgressBar()
        self.progress.setRange(0, 0)
        layout.addWidget(self.progress)

        self.output = QPlainTextEdit()
        self.output.setReadOnly(True)
        self.output.setPlainText("Waiting for administrator authentication…\n")
        layout.addWidget(self.output, 1)

        buttons = QHBoxLayout()
        buttons.addStretch(1)
        self.close_button = QPushButton("Close")
        self.close_button.setObjectName("Secondary")
        self.close_button.setEnabled(False)
        self.close_button.clicked.connect(self.accept)
        buttons.addWidget(self.close_button)
        layout.addLayout(buttons)

        self.process = QProcess(self)
        self.process.setProcessChannelMode(QProcess.ProcessChannelMode.MergedChannels)
        self.process.readyReadStandardOutput.connect(self.read_output)
        self.process.finished.connect(self.finished_process)
        self.process.errorOccurred.connect(self.process_error)
        self.process.start("pkexec", [HELPER_PATH, "install", target])

    def read_output(self) -> None:
        chunk = bytes(self.process.readAllStandardOutput()).decode(errors="replace")
        if chunk:
            self.output.moveCursor(QTextCursor.MoveOperation.End)
            self.output.insertPlainText(chunk)
            self.output.ensureCursorVisible()

    def finished_process(self, exit_code: int, _status: QProcess.ExitStatus) -> None:
        self.progress.setRange(0, 1)
        self.progress.setValue(1 if exit_code == 0 else 0)
        self.close_button.setEnabled(True)
        if exit_code == 0:
            self.output.appendPlainText("\nInstallation completed successfully.")
            self.close_button.setText("Done")
        else:
            self.output.appendPlainText(
                f"\nInstallation stopped with status {exit_code}. Review the log above."
            )

    def process_error(self, _error: QProcess.ProcessError) -> None:
        if self.process.state() == QProcess.ProcessState.NotRunning:
            self.progress.setRange(0, 1)
            self.progress.setValue(0)
            self.close_button.setEnabled(True)
            self.output.appendPlainText(
                "\nCould not start the authenticated installer. Ensure PolicyKit is running."
            )

    def reject(self) -> None:
        if self.process.state() != QProcess.ProcessState.NotRunning:
            answer = QMessageBox.question(
                self,
                "Installation in progress",
                "An installation is still running. Stop it and close this window?",
            )
            if answer != QMessageBox.StandardButton.Yes:
                return
            self.process.kill()
        super().reject()


class ProfileCard(QFrame):
    install_requested = pyqtSignal(str, str)

    def __init__(self, profile: dict) -> None:
        super().__init__()
        self.profile = profile
        self.setObjectName("Card")
        self.setMinimumHeight(255)
        self.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Fixed)

        layout = QVBoxLayout(self)
        layout.setContentsMargins(20, 20, 20, 20)
        layout.setSpacing(8)

        top = QHBoxLayout()
        icon = QLabel()
        icon.setPixmap(themed_icon(profile["icon"]).pixmap(QSize(34, 34)))
        top.addWidget(icon)
        top.addStretch(1)
        size = QLabel(profile["size"])
        size.setObjectName("Badge")
        top.addWidget(size)
        layout.addLayout(top)

        title = QLabel(profile["title"])
        title.setObjectName("CardTitle")
        layout.addWidget(title)

        subtitle = QLabel(profile["subtitle"])
        subtitle.setObjectName("CardSubtitle")
        layout.addWidget(subtitle)

        description = QLabel(profile["description"])
        description.setObjectName("Muted")
        description.setWordWrap(True)
        layout.addWidget(description)

        highlights = QLabel("  •  ".join(profile["highlights"]))
        highlights.setObjectName("Muted")
        highlights.setWordWrap(True)
        layout.addWidget(highlights)
        layout.addStretch(1)

        install = QPushButton("Install profile")
        install.setObjectName("Primary" if profile["id"] == "ultimate" else "Secondary")
        install.clicked.connect(
            lambda: self.install_requested.emit(profile["id"], profile["title"])
        )
        layout.addWidget(install, 0, Qt.AlignmentFlag.AlignRight)


class ApplicationCard(QFrame):
    action_requested = pyqtSignal(dict)

    def __init__(self, application: dict) -> None:
        super().__init__()
        self.application = application
        self.setObjectName("Card")
        self.setMinimumHeight(205)
        self.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Fixed)

        layout = QVBoxLayout(self)
        layout.setContentsMargins(18, 18, 18, 18)
        layout.setSpacing(9)

        top = QHBoxLayout()
        icon = QLabel()
        icon.setPixmap(themed_icon(application["icon"]).pixmap(QSize(32, 32)))
        top.addWidget(icon)
        top.addStretch(1)
        badge = QLabel(application["badge"])
        badge.setObjectName("Badge")
        top.addWidget(badge)
        layout.addLayout(top)

        title = QLabel(application["title"])
        title.setObjectName("CardTitle")
        layout.addWidget(title)

        description = QLabel(application["description"])
        description.setObjectName("Muted")
        description.setWordWrap(True)
        layout.addWidget(description)
        layout.addStretch(1)

        text = "Official download" if application["action"] == "url" else "Install"
        button = QPushButton(text)
        button.setObjectName("Secondary")
        button.clicked.connect(lambda: self.action_requested.emit(application))
        layout.addWidget(button, 0, Qt.AlignmentFlag.AlignRight)


class WelcomeWindow(QMainWindow):
    def __init__(self, catalog: dict) -> None:
        super().__init__()
        self.catalog = catalog
        self.about = load_about()
        self.setWindowTitle("Kilimanjaro Welcome")
        self.setWindowIcon(QIcon(str(LOGO_PATH)))
        self.resize(1180, 780)
        self.setMinimumSize(960, 650)

        root = QWidget()
        root.setObjectName("Root")
        self.setCentralWidget(root)
        outer = QHBoxLayout(root)
        outer.setContentsMargins(0, 0, 0, 0)
        outer.setSpacing(0)

        outer.addWidget(self.build_sidebar())
        self.pages = QStackedWidget()
        self.pages.addWidget(self.build_home_page())
        self.pages.addWidget(self.build_profiles_page())
        self.pages.addWidget(self.build_apps_page())
        self.pages.addWidget(self.build_system_page())
        outer.addWidget(self.pages, 1)
        self.select_page(0)

    def build_sidebar(self) -> QWidget:
        sidebar = QFrame()
        sidebar.setObjectName("Sidebar")
        sidebar.setFixedWidth(235)
        layout = QVBoxLayout(sidebar)
        layout.setContentsMargins(22, 26, 22, 22)
        layout.setSpacing(8)

        brand_row = QHBoxLayout()
        logo = QLabel()
        pixmap = QPixmap(str(LOGO_PATH))
        if not pixmap.isNull():
            logo.setPixmap(
                pixmap.scaled(
                    48,
                    48,
                    Qt.AspectRatioMode.KeepAspectRatio,
                    Qt.TransformationMode.SmoothTransformation,
                )
            )
        brand_row.addWidget(logo)
        names = QVBoxLayout()
        brand = QLabel("Kilimanjaro")
        brand.setObjectName("Brand")
        edition = QLabel("ULTIMATE SETUP")
        edition.setObjectName("Edition")
        names.addWidget(brand)
        names.addWidget(edition)
        brand_row.addLayout(names)
        layout.addLayout(brand_row)
        layout.addSpacing(24)

        navigation = [
            ("Home", "go-home"),
            ("Software profiles", "view-grid"),
            ("Featured apps", "applications-all"),
            ("This computer", "computer"),
        ]
        self.nav_buttons: list[QPushButton] = []
        for index, (title, icon_name) in enumerate(navigation):
            button = QPushButton(title)
            button.setProperty("nav", True)
            button.setProperty("active", False)
            button.setIcon(themed_icon(icon_name))
            button.setIconSize(QSize(20, 20))
            button.clicked.connect(lambda _checked=False, page=index: self.select_page(page))
            layout.addWidget(button)
            self.nav_buttons.append(button)

        layout.addStretch(1)
        private = QLabel("No telemetry\nNo silent proprietary installs")
        private.setObjectName("Muted")
        private.setWordWrap(True)
        layout.addWidget(private)
        layout.addSpacing(10)
        version = QLabel("Kilimanjaro OS 0.1.0 · Uhuru")
        version.setObjectName("Edition")
        layout.addWidget(version)
        return sidebar

    def page_shell(self, title: str, body: str) -> tuple[QWidget, QVBoxLayout]:
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setContentsMargins(34, 30, 34, 26)
        layout.setSpacing(12)
        heading = QLabel(title)
        heading.setObjectName("PageTitle")
        layout.addWidget(heading)
        intro = QLabel(body)
        intro.setObjectName("PageBody")
        intro.setWordWrap(True)
        layout.addWidget(intro)
        layout.addSpacing(8)
        return page, layout

    def build_home_page(self) -> QWidget:
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setContentsMargins(34, 30, 34, 26)
        layout.setSpacing(16)

        if is_live_session():
            notice = QFrame()
            notice.setObjectName("Notice")
            notice_layout = QHBoxLayout(notice)
            notice_layout.setContentsMargins(14, 10, 14, 10)
            icon = QLabel()
            icon.setPixmap(themed_icon("dialog-warning").pixmap(22, 22))
            notice_layout.addWidget(icon)
            message = QLabel(
                "Live session: software installed here is temporary and disappears "
                "after shutdown. Use it to test profiles before installing Kilimanjaro OS."
            )
            message.setWordWrap(True)
            notice_layout.addWidget(message, 1)
            layout.addWidget(notice)

        hero = QFrame()
        hero.setObjectName("Hero")
        hero_layout = QHBoxLayout(hero)
        hero_layout.setContentsMargins(30, 28, 28, 28)
        hero_layout.setSpacing(26)

        copy = QVBoxLayout()
        eyebrow = QLabel("YOUR SYSTEM · YOUR WORKFLOW")
        eyebrow.setObjectName("Eyebrow")
        copy.addWidget(eyebrow)
        title = QLabel("Ready for ambitious work.")
        title.setObjectName("HeroTitle")
        copy.addWidget(title)
        body = QLabel(
            "Build a focused Kilimanjaro installation for gaming, AI development, "
            "office work, meetings or creative production—without unsafe scripts "
            "or mystery repositories."
        )
        body.setObjectName("HeroBody")
        body.setWordWrap(True)
        copy.addWidget(body)
        copy.addSpacing(10)
        actions = QHBoxLayout()
        profiles = QPushButton("Choose software profiles")
        profiles.setObjectName("Primary")
        profiles.clicked.connect(lambda: self.select_page(1))
        actions.addWidget(profiles)
        apps = QPushButton("Browse featured apps")
        apps.setObjectName("Secondary")
        apps.clicked.connect(lambda: self.select_page(2))
        actions.addWidget(apps)
        actions.addStretch(1)
        copy.addLayout(actions)
        hero_layout.addLayout(copy, 1)

        art = QLabel()
        pixmap = QPixmap(str(LOGO_PATH))
        if not pixmap.isNull():
            art.setPixmap(
                pixmap.scaled(
                    155,
                    155,
                    Qt.AspectRatioMode.KeepAspectRatio,
                    Qt.TransformationMode.SmoothTransformation,
                )
            )
        hero_layout.addWidget(art)
        layout.addWidget(hero)

        section = QLabel("Designed as a complete workstation")
        section.setObjectName("CardTitle")
        layout.addWidget(section)
        grid = QGridLayout()
        grid.setSpacing(12)
        features = [
            ("applications-games", "Gaming", "Steam, Wine, launchers and performance overlays"),
            ("applications-development", "AI & Code", "Agents, containers, compilers and modern SDKs"),
            ("applications-multimedia", "Create", "OBS, editing, graphics and hardware encoding"),
            ("security-high", "Controlled", "Signed sources, authentication and explicit consent"),
        ]
        for index, (icon_name, name, text) in enumerate(features):
            card = QFrame()
            card.setObjectName("Card")
            card_layout = QVBoxLayout(card)
            card_layout.setContentsMargins(17, 16, 17, 16)
            icon = QLabel()
            icon.setPixmap(themed_icon(icon_name).pixmap(28, 28))
            card_layout.addWidget(icon)
            label = QLabel(name)
            label.setObjectName("CardTitle")
            card_layout.addWidget(label)
            detail = QLabel(text)
            detail.setObjectName("Muted")
            detail.setWordWrap(True)
            card_layout.addWidget(detail)
            grid.addWidget(card, index // 2, index % 2)
        layout.addLayout(grid)
        layout.addStretch(1)

        footer = QHBoxLayout()
        self.startup_checkbox = QCheckBox("Continue showing this welcome screen on future logins")
        self.startup_checkbox.setChecked(False)
        footer.addWidget(self.startup_checkbox)
        footer.addStretch(1)
        finish = QPushButton("Finish setup")
        finish.setObjectName("Secondary")
        finish.clicked.connect(self.finish_setup)
        footer.addWidget(finish)
        layout.addLayout(footer)
        return page

    def build_profiles_page(self) -> QWidget:
        page, layout = self.page_shell(
            "Software profiles",
            "Install only what matches this computer. Administrator authentication is "
            "required, and the installation log stays visible throughout the operation.",
        )
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        content = QWidget()
        grid = QGridLayout(content)
        grid.setContentsMargins(0, 0, 8, 8)
        grid.setSpacing(14)
        for index, profile in enumerate(self.catalog["profiles"]):
            card = ProfileCard(profile)
            card.install_requested.connect(self.install_target)
            if profile["id"] == "ultimate":
                grid.addWidget(card, index // 2, 0, 1, 2)
            else:
                grid.addWidget(card, index // 2, index % 2)
        grid.setRowStretch((len(self.catalog["profiles"]) + 1) // 2, 1)
        scroll.setWidget(content)
        layout.addWidget(scroll, 1)
        return page

    def build_apps_page(self) -> QWidget:
        page, layout = self.page_shell(
            "Featured applications",
            "Proprietary software is installed only when you request it. Repository-backed "
            "apps receive normal updates; vendor downloads open their official website.",
        )
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        content = QWidget()
        grid = QGridLayout(content)
        grid.setContentsMargins(0, 0, 8, 8)
        grid.setSpacing(14)
        for index, application in enumerate(self.catalog["applications"]):
            card = ApplicationCard(application)
            card.action_requested.connect(self.application_action)
            grid.addWidget(card, index // 2, index % 2)
        grid.setRowStretch((len(self.catalog["applications"]) + 1) // 2, 1)
        scroll.setWidget(content)
        layout.addWidget(scroll, 1)
        return page

    def build_system_page(self) -> QWidget:
        page, page_layout = self.page_shell(
            "This computer",
            "Kilimanjaro identity and the hardware visible to this session. In a VM, "
            "the graphics entry describes the virtual adapter rather than the host GPU.",
        )
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        content = QWidget()
        layout = QVBoxLayout(content)
        layout.setContentsMargins(0, 0, 8, 8)
        layout.setSpacing(14)
        scroll.setWidget(content)
        page_layout.addWidget(scroll, 1)

        details = QFrame()
        details.setObjectName("Card")
        details_layout = QGridLayout(details)
        details_layout.setContentsMargins(22, 20, 22, 20)
        details_layout.setHorizontalSpacing(24)
        details_layout.setVerticalSpacing(14)

        identity = QFrame()
        identity.setObjectName("Hero")
        identity_layout = QHBoxLayout(identity)
        identity_layout.setContentsMargins(18, 15, 18, 15)
        logo = QLabel()
        pixmap = QPixmap(str(LOGO_PATH))
        if not pixmap.isNull():
            logo.setPixmap(
                pixmap.scaled(
                    64,
                    64,
                    Qt.AspectRatioMode.KeepAspectRatio,
                    Qt.TransformationMode.SmoothTransformation,
                )
            )
        identity_layout.addWidget(logo)
        identity_text = QVBoxLayout()
        product_name = QLabel(
            f"{self.about['name']} {self.about['version']} · {self.about['codename']}"
        )
        product_name.setObjectName("CardTitle")
        identity_text.addWidget(product_name)
        attribution = QLabel(
            f"Created by {self.about['author']}  ·  Based on {self.about['based_on']}  ·  {self.about['desktop']}"
        )
        attribution.setObjectName("Muted")
        attribution.setWordWrap(True)
        identity_text.addWidget(attribution)
        contact = QLabel(
            f'<a href="mailto:{self.about["email"]}">{self.about["email"]}</a>'
        )
        contact.setOpenExternalLinks(True)
        identity_text.addWidget(contact)
        purpose = QLabel(self.about["purpose"])
        purpose.setObjectName("Muted")
        purpose.setWordWrap(True)
        identity_text.addWidget(purpose)
        identity_layout.addLayout(identity_text, 1)
        layout.addWidget(identity)

        for row, (name, value) in enumerate(hardware_summary().items()):
            key = QLabel(name)
            key.setObjectName("Muted")
            details_layout.addWidget(key, row, 0)
            data = QLabel(value)
            data.setWordWrap(True)
            details_layout.addWidget(data, row, 1)
        details_layout.setColumnStretch(1, 1)
        layout.addWidget(details)

        notice = QFrame()
        notice.setObjectName("GoodNotice")
        notice_layout = QHBoxLayout(notice)
        notice_layout.setContentsMargins(16, 13, 16, 13)
        shield = QLabel()
        shield.setPixmap(themed_icon("security-high").pixmap(24, 24))
        notice_layout.addWidget(shield)
        text = QLabel(
            "Kilimanjaro Welcome never stores account credentials or API keys. "
            "AI services and proprietary applications ask you to sign in directly."
        )
        text.setWordWrap(True)
        notice_layout.addWidget(text, 1)
        layout.addWidget(notice)

        actions = QHBoxLayout()
        settings = QPushButton("Open System Settings")
        settings.setObjectName("Primary")
        settings.clicked.connect(self.open_system_settings)
        actions.addWidget(settings)
        info = QPushButton("Open Info Center")
        info.setObjectName("Secondary")
        info.clicked.connect(self.open_info_center)
        actions.addWidget(info)
        discover = QPushButton("Open Discover")
        discover.setObjectName("Secondary")
        discover.clicked.connect(self.open_discover)
        actions.addWidget(discover)
        actions.addStretch(1)
        layout.addLayout(actions)
        layout.addStretch(1)
        return page

    def select_page(self, index: int) -> None:
        self.pages.setCurrentIndex(index)
        for button_index, button in enumerate(self.nav_buttons):
            button.setProperty("active", button_index == index)
            button.style().unpolish(button)
            button.style().polish(button)

    def install_target(self, target: str, title: str) -> None:
        if is_live_session():
            answer = QMessageBox.warning(
                self,
                "Temporary live session",
                "This is a disposable live session. The installation is useful for testing, "
                "but it will be lost after shutdown. Continue?",
                QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.Cancel,
                QMessageBox.StandardButton.Cancel,
            )
            if answer != QMessageBox.StandardButton.Yes:
                return
        dialog = InstallDialog(target, title, self)
        dialog.exec()

    def application_action(self, application: dict) -> None:
        if application["action"] == "url":
            QDesktopServices.openUrl(QUrl(application["target"]))
            return
        self.install_target(application["target"], application["title"])

    def open_discover(self) -> None:
        executable = shutil.which("plasma-discover") or shutil.which("discover")
        if executable:
            QProcess.startDetached(executable, [])
        else:
            QMessageBox.information(self, "Discover", "KDE Discover is not installed yet.")

    def open_system_settings(self) -> None:
        executable = shutil.which("systemsettings")
        if executable:
            QProcess.startDetached(executable, [])
        else:
            QMessageBox.information(self, "System Settings", "KDE System Settings is not installed yet.")

    def open_info_center(self) -> None:
        executable = shutil.which("kinfocenter")
        if executable:
            QProcess.startDetached(executable, [])
        else:
            QMessageBox.information(self, "Info Center", "KDE Info Center is not installed yet.")

    def finish_setup(self) -> None:
        if self.startup_checkbox.isChecked():
            if STATE_PATH.exists():
                STATE_PATH.unlink()
        else:
            STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
            STATE_PATH.write_text("completed\n", encoding="utf-8")
        self.close()


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Kilimanjaro OS first-run setup")
    parser.add_argument("--first-run", action="store_true", help="exit if setup was completed")
    return parser.parse_args()


def main() -> int:
    arguments = parse_arguments()
    if arguments.first_run and STATE_PATH.exists():
        return 0

    app = QApplication(sys.argv)
    app.setApplicationName("Kilimanjaro Welcome")
    app.setOrganizationName("Kilimanjaro OS")
    app.setStyle("Fusion")
    app.setStyleSheet(STYLE)

    try:
        catalog = load_catalog()
    except (OSError, json.JSONDecodeError, KeyError) as error:
        QMessageBox.critical(None, "Kilimanjaro Welcome", f"Could not load the software catalogue:\n{error}")
        return 1

    window = WelcomeWindow(catalog)
    window.show()
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
