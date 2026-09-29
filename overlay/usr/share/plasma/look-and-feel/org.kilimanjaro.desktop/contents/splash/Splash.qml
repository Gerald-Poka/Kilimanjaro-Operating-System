import QtQuick

Rectangle {
    id: root
    color: "#12141a"
    property int stage

    Image {
        id: logo
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height) * 0.22
        height: width
        fillMode: Image.PreserveAspectFit
        source: "file:///usr/share/pixmaps/kilimanjaro-logo.png"
        opacity: root.stage >= 1 ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 500 }
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: logo.bottom
        anchors.topMargin: 18
        text: "Kilimanjaro OS"
        color: "#f3f1e8"
        font.family: "Inter"
        font.pixelSize: 24
        font.weight: Font.DemiBold
        opacity: logo.opacity
    }
}
