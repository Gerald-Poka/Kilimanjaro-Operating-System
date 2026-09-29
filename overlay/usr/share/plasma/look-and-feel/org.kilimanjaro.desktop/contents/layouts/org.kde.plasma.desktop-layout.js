var desktopsArray = desktopsForActivity(currentActivity());

for (var i = 0; i < desktopsArray.length; i++) {
    var desktop = desktopsArray[i];
    desktop.wallpaperPlugin = "org.kde.image";
    desktop.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    desktop.writeConfig("Image", "file:///usr/share/wallpapers/Kilimanjaro/contents/images/3840x2160.png");
    desktop.writeConfig("FillMode", 2);
}

var panel = new Panel();
panel.location = "bottom";
panel.height = 52;
panel.floating = true;

panel.addWidget("org.kde.plasma.kickoff");

var tasks = panel.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", "applications:calamares-install-debian.desktop,applications:org.kde.dolphin.desktop,applications:firefox-esr.desktop,applications:libreoffice-startcenter.desktop,applications:org.kde.konsole.desktop");

panel.addWidget("org.kde.plasma.marginsseparator");
panel.addWidget("org.kde.plasma.systemtray");
panel.addWidget("org.kde.plasma.digitalclock");
panel.addWidget("org.kde.plasma.showdesktop");
