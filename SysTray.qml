import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray

RowLayout {
    id: trayRoot
    spacing: 5

    implicitWidth: childrenRect.width
    implicitHeight: 30

    Repeater {
        model: SystemTray.items

        delegate: Rectangle {
            id: trayItemDelegate
            required property var modelData

            implicitWidth: 24
            implicitHeight: 24
            color: "transparent"
            border.color: "white"
            border.width: 1

            IconImage {
                anchors.fill: parent
                anchors.margins: 2
                source: modelData.icon
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onClicked: (mouse) => {
                    if (mouse.button === Qt.LeftButton) {
                        modelData.activate();
                    } else if (mouse.button === Qt.RightButton) {
                        if (modelData.menu) {
                            // 1. Map the clicked coordinates relative to the entire main bar window
                            let globalPos = trayItemDelegate.mapToItem(mainBar.contentItem, mouseX, mouseY);

                            // 2. Pass the mapped global bar coordinates to the display method
                            modelData.display(mainBar, globalPos.x, globalPos.y+15);
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        console.log("SystemTray items on startup: " + SystemTray.items.values.length);
    }

    Connections {
        target: SystemTray.items
        function onObjectInsertedPost(object, index) {
            console.log("Tray item added: " + object.title);
        }
    }
}
