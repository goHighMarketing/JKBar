import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray

RowLayout {
    id: trayRoot

    // Smooth container padding gaps between incoming tray icons
    spacing: 8
    Layout.alignment: Qt.AlignVCenter

    // ================= DYNAMIC COLLAPSE ENGINE =================
    // FIX 1: Read the true .values array length property
    // The RowLayout completely collapses to 0x0 pixels when empty.
    visible: SystemTray.items.values.length > 0
    // ============================================================

    // Background panel frame wrapper that expands dynamically as icons enter
    Rectangle {
        id: trayContainer

        // Dynamically calculates pixel width based on the active icon count
        implicitWidth: trayRepeater.count * 24 + ((trayRepeater.count - 1) * trayRoot.spacing) + 12
        implicitHeight: 24
        radius: 6
        color: "#181825" // Catppuccin Mantle dark background
        border.color: "#313244"
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            spacing: trayRoot.spacing

            Repeater {
                id: trayRepeater

                // FIX 2: Target the .values parameter array so QML can iterate properly
                model: SystemTray.items.values

                delegate: Item {
                    implicitWidth: 16
                    implicitHeight: 16
                    Layout.alignment: Qt.AlignVCenter

                    // FIX 3: Native Menu Anchor captures applet popup window requests cleanly
                    QsMenuAnchor {
                        id: menuAnchor
                        menu: modelData.menu
                    }

                    Image {
                        anchors.fill: parent
                        source: modelData.icon
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        onClicked: (mouse) => {
                            if (mouse.button === Qt.LeftButton) {
                                // Triggers the default action (e.g. opens application window)
                                modelData.activate();
                            } else if (mouse.button === Qt.RightButton) {
                                // Maps native app drop-downs (like Wi-Fi lists, Bluetooth toggles) safely
                                if (modelData.hasMenu) {
                                    menuAnchor.open();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
