export const wallpapers = [
  {
    id: "sunset",
    name: "Summit at sunset",
    mood: "A little closer to extraordinary.",
  },
  {
    id: "dawn",
    name: "Kilimanjaro dawn",
    mood: "Every great idea starts somewhere.",
  },
  {
    id: "blue-hour",
    name: "Blue hour",
    mood: "Find your focus. Make your mark.",
  },
  {
    id: "green-morning",
    name: "Green morning",
    mood: "Room for your next chapter.",
  },
  {
    id: "glacier",
    name: "Uhuru glacier",
    mood: "A fresh perspective, every day.",
  },
  {
    id: "savanna",
    name: "Savanna gold",
    mood: "Rooted here. Ready to go further.",
  },
  {
    id: "moonlight",
    name: "Moonlight",
    mood: "Make space for your next idea.",
  },
  {
    id: "forest-mist",
    name: "Forest mist",
    mood: "A quieter kind of inspiration.",
  },
  {
    id: "sea-of-clouds",
    name: "Sea of clouds",
    mood: "See beyond the everyday.",
  },
  {
    id: "amber-highlands",
    name: "Amber highlands",
    mood: "Warm light. Fresh possibilities.",
  },
  { id: "violet-twilight", name: "Violet twilight", mood: "Your own horizon." },
];

export const categories = [
  "Everyday",
  "Office & learning",
  "Development",
  "Gaming",
  "Creation",
  "Connect",
];
export const applications = [
  {
    name: "Firefox",
    category: "Everyday",
    icon: "globe",
    status: "Included",
    text: "Browse with reduced telemetry and Tanzanian government bookmarks.",
  },
  {
    name: "VLC",
    category: "Everyday",
    icon: "play",
    status: "Included",
    text: "A familiar player for your local video and audio collection.",
  },
  {
    name: "KDE Connect",
    category: "Everyday",
    icon: "phone",
    status: "Included",
    text: "Connect your phone and desktop on your local network.",
  },
  {
    name: "Google Chrome",
    category: "Everyday",
    icon: "globe",
    status: "Optional setup",
    text: "Welcome offers installation from Google’s signed repository. Not bundled in the base ISO.",
  },
  {
    name: "KCalc & Konsole",
    category: "Everyday",
    icon: "code",
    status: "Included",
    text: "A desktop calculator and a capable terminal, ready when you need them.",
  },
  {
    name: "Sound & recovery",
    category: "Everyday",
    icon: "layers",
    status: "Included",
    text: "PulseAudio-compatible volume control and Timeshift. Snapshot destinations and schedules need configuration.",
  },
  {
    name: "LibreOffice",
    category: "Office & learning",
    icon: "file",
    status: "Included",
    text: "Documents, spreadsheets and presentations, without a subscription.",
  },
  {
    name: "Kiwix & GCompris",
    category: "Office & learning",
    icon: "book",
    status: "Included",
    text: "Offline reading and educational activities. Reading content is separate.",
  },
  {
    name: "WPS Office",
    category: "Office & learning",
    icon: "file",
    status: "Official download",
    text: "Available through the vendor download link in Welcome; not bundled.",
  },
  {
    name: "Developer toolchain",
    category: "Development",
    icon: "code",
    status: "Optional profile",
    text: "Git, Python, Node.js, Rust and container tools via the Development profile.",
  },
  {
    name: "Cursor & AI agents",
    category: "Development",
    icon: "spark",
    status: "Optional setup",
    text: "Welcome offers Cursor, Claude Code and Gemini CLI setup. Vendor accounts may be required.",
  },
  {
    name: "ChatGPT & Codex",
    category: "Development",
    icon: "spark",
    status: "Vendor link",
    text: "Welcome links to the official vendor page. Availability depends on the vendor.",
  },
  {
    name: "Steam & Lutris",
    category: "Gaming",
    icon: "game",
    status: "Optional profile",
    text: "Choose Gaming Ready for launchers and Linux gaming tools.",
  },
  {
    name: "Wine & Proton tools",
    category: "Gaming",
    icon: "game",
    status: "Optional profile",
    text: "Windows-game compatibility tools. Support varies by game and hardware.",
  },
  {
    name: "OBS Studio",
    category: "Creation",
    icon: "record",
    status: "Included",
    text: "Capture your screen and create streams or recordings.",
  },
  {
    name: "Blender & Kdenlive",
    category: "Creation",
    icon: "layers",
    status: "Optional profile",
    text: "3D and video-editing tools through the Creator Studio profile.",
  },
  {
    name: "Zoom & Slack",
    category: "Connect",
    icon: "users",
    status: "Optional setup",
    text: "Install sandboxed apps through Welcome. Downloads and sign-in are separate.",
  },
  {
    name: "Microsoft Teams",
    category: "Connect",
    icon: "users",
    status: "Web launcher",
    text: "A shortcut to Teams on the web, not a native Linux Teams client.",
  },
  {
    name: "Spotify & Discord",
    category: "Connect",
    icon: "music",
    status: "Optional setup",
    text: "Music and community apps available as separate sandboxed installs.",
  },
];

export const faqs = [
  [
    "Is this ready for my everyday computer?",
    "Not yet. Version 0.1.0 is a development build. Start in a disposable VM; physical hardware, update/recovery and wider installation testing remain release gates. Back up your files before any real installation.",
  ],
  [
    "Does Kilimanjaro work without internet?",
    "The base desktop and local applications work offline, and the base installer has completed an offline UEFI VM installation. Downloading optional apps, Kiwix content and updates still needs internet or separately supplied files. Signed offline update bundles are planned, not implemented.",
  ],
  [
    "Is the whole interface in Kiswahili?",
    "Kiswahili locale and dictionary support are configured, with English fallback. The Welcome interface is currently English; complete Kiswahili translation remains in progress.",
  ],
  [
    "What about NVIDIA and ASUS ROG laptops?",
    "The image now ships the proprietary NVIDIA driver together with its GSP firmware, so NVIDIA cards get hardware acceleration out of the box and AMD/Intel machines keep using Mesa. The target deployment runs with Secure Boot disabled in the PC BIOS, so no signature is enforced and no Secure Boot module enrolment is needed. It is built locally by dkms, which means a kernel update triggers a module rebuild that has not yet been tested; a failed rebuild would leave the machine unable to start. No physical NVIDIA GPU has been verified yet. ASUS ROG fan controls and graphics-mode switching are not yet integrated.",
  ],
  [
    "Is Kilimanjaro related to Debian, Nobara or Kali?",
    "Kilimanjaro uses Debian 13 packages and the Linux kernel with KDE Plasma. It is an independent project, not endorsed by Debian, Nobara or Kali. The website uses Kilimanjaro’s own artwork and identity.",
  ],
];
