import QtQuick 2.0
import calamares.slideshow 1.0

Presentation {
    function onEnter() {}
    function onLeave() {}
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#171a21"
            Column {
                anchors.centerIn: parent
                spacing: 24
                width: parent.width * 0.8
                Image {
                    source: "kilimanjaro-logo.svg"
                    width: 120
                    height: 120
                    anchors.horizontalCenter: parent.horizontalCenter
                    fillMode: Image.PreserveAspectFit
                }
                Text {
                    width: parent.width
                    text: qsTr("Welcome to Kilimanjaro OS")
                    color: "#f59e42"
                    font.pixelSize: 28
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
                Text {
                    width: parent.width
                    text: qsTr("Your desktop is being installed. Keep this computer powered on until installation finishes.")
                    color: "#f3f1e8"
                    font.pixelSize: 17
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
