//@ pragma UseQApplication
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    // --- STATE VARIABLES ---
    property int activeWorkspace: 1
    property bool controlCenterOpen: false
    property bool isAppFullscreen: false
    property bool nightLightActive: false

    // --- DATA FETCHING & PROCESSES ---

    // 1. BSPWM Workspace Tracker
    Process {
        id: bspwmListener
        command: ["bspc", "subscribe", "report"]
        running: true

        stdout: SplitParser {
            onRead: (data) => {
                let report = data.toString().trim();
                let match = report.match(/:[OF](\d|I+)/);
                if (match) {
                    let wsName = match[1];
                    if (wsName === "I") root.activeWorkspace = 1;
                    else if (wsName === "II") root.activeWorkspace = 2;
                    else if (wsName === "III") root.activeWorkspace = 3;
                    else if (wsName === "IV") root.activeWorkspace = 4;
                    else if (!isNaN(wsName)) root.activeWorkspace = parseInt(wsName);
                }
            }
        }
    }

        // 2. FIXED: BSPWM Fullscreen Tracker (With Secure Shell Trapping)
    Process {
        id: bspwmFullscreenListener
        // Triggers instantly on desktop changes or window layout shifts
        command: ["bspc", "subscribe", "node_state", "desktop_focus"]
        running: true
        
        stdout: SplitParser {
            onRead: (data) => {
                bspcCheckCurrentFullscreen.running = true;
            }
        }
    }

    // Secondary sub-process to evaluate focused viewport layout masks safely
    Process {
        id: bspcCheckCurrentFullscreen
        // Shell Script Trap: Checks for a fullscreen node locally. 
        // If found, echoes "yes". If empty/error, safely echoes "no" and forces exit code 0.
        command: ["sh", "-c", "if bspc query -N -n .local.fullscreen > /dev/null 2>&1; then echo 'yes'; else echo 'no'; fi"]
        running: false
        
        stdout: SplitParser {
            onRead: (data) => {
                let response = data.toString().trim();
                
                if (response === "yes") {
                    root.isAppFullscreen = true;
                } else {
                    root.isAppFullscreen = false;
                }
            }
        }
    }


        // --- THE MAIN BAR PANEL ---
    PanelWindow {
        id: mainBar
        anchors.top: true
        anchors.left: true
        anchors.right: true
        implicitHeight: 40
        color: "#1e1e2e" // Catppuccin Mocha base

        // Bind visibility to the inverse of our fullscreen state! (Hide bar when apps are fullscreen.)
        visible: !root.isAppFullscreen

        margins {
            top: 0
            left: 3
            right: 3
            bottom: 0
        }

        // We use a plain Item container with explicit margins to prevent container overflow
        Item {
            anchors.fill: parent
            anchors.leftMargin: 15
            anchors.rightMargin: 15

            // ================= LEFT: LAUNCHER & WORKSPACES =================
            Workspaces {
                id: wmState
            }

            Row {
                id: leftWorkspaceBar
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12 // Comfortable spacing between the launcher and workspace dots

                // ---    THE ROFI APP LAUNCHER BUTTON ---
                Rectangle {
                    implicitWidth: 32
                    implicitHeight: 28
                    radius: 6
                    color: "#74c7ec" // Catppuccin Sapphire
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        font.bold: true
                        color: "#11111b"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            root.controlCenterOpen = false;

                            // FIXED: Wrapping inside sh -c allows terminal environmental shortcuts like ~ or $HOME to resolve natively
                            Quickshell.execDetached([
                                "sh", "-c",
                                "rofi -show drun -modi drun -line-padding 4 -hide-scrollbar -show-icons -theme ~/.config/bspwm/rofi/config-jkbar.rasi"
                            ]);
                        }
                    }
                }

                // WALLPAPER TRIGGER BUTTON
                Rectangle {
                    id: wallpaperButton
                    width: 24
                    height: 24
                    color: wallpaperMouse.containsMouse ? "#313244" : "transparent"
                    border.color: "white"
                    border.width: 1
                    radius: 4

                    Text {
                        anchors.centerIn: parent
                        text: "🖼️"
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: wallpaperMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            // Toggles the visibility state cleanly on click
                            wallpaperPopup.visible = !wallpaperPopup.visible;
                        }
                    }
                }

                // NATIVE QUICKSHELL POPUP WINDOW
                PopupWindow {
                    id: wallpaperPopup
                    visible: false

                    implicitWidth: 1850
                    implicitHeight: 250

                    // Connect the popup to the main bar window
                    anchor.window: mainBar

                    // POSITIONING MATRIX:
                    // Shifts layout left (-296) and drops it nicely below the bar (6)
                    anchor.rect: wallpaperButton.mapToItem(mainBar.contentItem, -296, 40, wallpaperButton.width, wallpaperButton.height)

                    // THE CLOSING FIX:
                    // Native flag tells Quickshell to close the window when you click outside of it
                    grabFocus: true

                    WallpaperSelector {
                        anchors.fill: parent
                    }
                }

                // --- THE EXSTING REPEATER FOR WORKSPACES ---
                Row {
                    spacing: 8
                    anchors.verticalCenter: parent.verticalCenter

                    Repeater {
                        model: wmState.occupiedWorkspaces

                        delegate: Rectangle {
                            width: 28
                            height: 28
                            radius: 6
                            color: modelData.isFocused ? "#3d59a1" : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: modelData.name
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                                font.weight: modelData.isFocused ? Font.Bold : Font.Normal

                                color: {
                                    if (modelData.isUrgent) return "#f38ba8";
                                    if (modelData.isFocused) return "#ffffff";
                                    if (modelData.isOccupied) return "#7aa2f7";
                                    return "#565f89";
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    Quickshell.execDetached(["bspc", "desktop", "-f", modelData.name])
                                }
                            }
                        }
                    }
                }
            } // End of Left Row


            // Optional: You can put your ActiveWindow title right next to the workspaces if you want
            ActiveWindow {
                anchors.left: leftWorkspaceBar.right
                anchors.leftMargin: 15
                anchors.verticalCenter: parent.verticalCenter
            }

            // ================= CENTER: CLOCK =================
            Clock {
                anchors.centerIn: parent
            }

            // ================= RIGHT: STATUS & CONTROLS =================
            // Row anchors straight to the right side, forcing perfect sequential layout order without overlapping
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 15

                Weather {
                    anchors.verticalCenter: parent.verticalCenter
                }

                VolumeControl {
                    anchors.verticalCenter: parent.verticalCenter
                }

                SysTray {
                    anchors.verticalCenter: parent.verticalCenter
                    // Coerce sizing properties safely
                    width: implicitWidth > 0 ? implicitWidth : 60
                    height: 28
               }


                               // Control Center Trigger Button
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 35
                    height: 28
                    radius: 6
                    color: root.controlCenterOpen ? "#f5c2e7" : "#313244"

                    Text {
                        anchors.centerIn: parent
                        text: "⚙️"
                        color: root.controlCenterOpen ? "#11111b" : "#cdd6f4"
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (root.controlCenterOpen) {
                                root.controlCenterOpen = false;
                            } else {
                                root.controlCenterOpen = true;
                                if (root.controlCenterOpen) root.weatherDropdownOpen = false;
                            }
                        }
                    }
                }
            } // Closes the Status/Controls Row
        } // Closes the mainBar inner Item container
    } // Closes mainBar PanelWindow safely

    // --- THE CONTROL CENTER FLYOUT CONTAINER ---
    // Instead of a standalone floating block, we make this a full screen invisible shield
    // --- THE CONTROL CENTER FLYOUT CONTAINER ---
    PanelWindow {
            id: controlCenterOverlay
            visible: root.controlCenterOpen

            anchors.top: true
            anchors.right: true
            implicitWidth: 680
            implicitHeight: 650
            color: "#181825" // Catppuccin Mocha Crust

            margins {
                top: 0
                right: 4
            }
/*
            // Lock this panel to cover the entire viewport surface
            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            // FIX: The standard way to enforce alpha channels natively in Quickshell
            // #00 handles the transparency hex mask directly
            color: "#00000000"

            // Prevents bspwm from creating tiling struts or borders around the sheet
            exclusionMode: ExclusionMode.None

            // ================= FULL SCREEN MOUSE SHIELD =================
            // Clicking this invisible background triggers an instant dismissal
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.controlCenterOpen = false;
                }
            }
            // ============================================================
*/
            // --- THE ACTUAL VISUAL CONTROL CENTER RECTANGLE ---
            Rectangle {
                id: controlCenter
                width: 660
                height: 650
                color: "#181825" // Catppuccin Mocha Crust
                radius: 12

                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: 2
                anchors.rightMargin: 15
                anchors.leftMargin: 14

                // Prevent clicks inside the dashboard from passing through to the shield
                MouseArea {
                    anchors.fill: parent
                    propagateComposedEvents: false
                    onClicked: (mouse) => mouse.accepted = true
                }

                // Apply a single subtle border outline
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.color: "#313244"
                    border.width: 1
                    radius: 12
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 16

                    // ================= BACKEND TRACKER REGISTRATION =================
                    // Placing these invisible components here keeps them active in memory
                    // but safely removes them from the ColumnLayout visual calculation stream.
                    CpuMonitor { id: cpuStats }
                    MemoryMonitor { id: ramStats }
                    DiskMonitor { id: diskStats }
                    // =================================================================

                    // 1. Header Section (Now guaranteed to render first)
                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "Control Center"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 18
                            font.bold: true
                            color: "#cdd6f4"
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "Fedora Ultramarine"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            color: "#a6adc8"
                        }
                    }

                    // 2. Quick Settings Grid (Toggles) (Now guaranteed to render second)
                    GridLayout {
                        columns: 2
                        rows: 2
                        columnSpacing: 12
                        rowSpacing: 12
                        Layout.fillWidth: true

                        // Volume Mute Button
                        Rectangle {
                            Layout.fillWidth: true
                            height: 50
                            radius: 8
                            color: "#313244"

                            Text {
                                anchors.centerIn: parent
                                text: "🔊 Mute Volume"
                                font.family: "JetBrainsMono Nerd Font"
                                color: "#cdd6f4"
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    Quickshell.execDetached(["pamixer", "-t"]);
                                    if (typeof volPoll !== 'undefined') volPoll.running = true;
                                }
                            }
                        }

                        // DND / Fullscreen Toggle Override
                        Rectangle {
                            Layout.fillWidth: true
                            height: 50
                            radius: 8
                            color: root.isAppFullscreen ? "#f38ba8" : "#313244"

                            Text {
                                anchors.centerIn: parent
                                text: root.isAppFullscreen ? "👁️ Bar: Hidden" : "👁️ Bar: Locked"
                                font.family: "JetBrainsMono Nerd Font"
                                color: root.isAppFullscreen ? "#11111b" : "#cdd6f4"
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.isAppFullscreen = !root.isAppFullscreen
                            }
                        }

                        // Night Light / Gamma Toggle
                        Rectangle {
                            Layout.fillWidth: true
                            height: 50
                            radius: 8
                            color: root.nightLightActive ? "#fab387" : "#313244"

                            Text {
                                anchors.centerIn: parent
                                text: root.nightLightActive ? "🌙 Night Light: ON" : "🌙 Night Light: OFF"
                                font.family: "JetBrainsMono Nerd Font"
                                color: root.nightLightActive ? "#11111b" : "#cdd6f4"
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    root.nightLightActive = !root.nightLightActive;
                                    if (root.nightLightActive) {
                                        Quickshell.execDetached(["redshift", "-O", "4500k"]);
                                    } else {
                                        Quickshell.execDetached(["redshift", "-x"]);
                                    }
                                }
                            }
                        }

                        // Exit Session Button
                        Rectangle {
                            Layout.fillWidth: true
                            height: 50
                            radius: 8
                            color: "#f38ba8"

                            Text {
                                anchors.centerIn: parent
                                text: "🛑 Exit bspwm"
                                font.family: "JetBrainsMono Nerd Font"
                                font.bold: true
                                color: "#11111b"
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: Quickshell.execDetached(["bspc", "quit"])
                            }
                        }
                    }

                    // 3. System Statistics Section (Now guaranteed to render third)
                    // System Statistics Section
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Text {
                            text: "System Resources"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            color: "#a6adc8"
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: "#313244"
                        }

                        // --- ROW 1: CPU PROGRESS METER ---
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Text {
                                text: "💻 CPU"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                                color: "#cdd6f4"
                                Layout.preferredWidth: 50
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 12
                                radius: 6
                                color: "#313244"

                                Rectangle {
                                    width: parent.width * (cpuStats.usage / 100)
                                    height: parent.height
                                    radius: 6
                                    color: cpuStats.usage > 80 ? "#f38ba8" : (cpuStats.usage > 50 ? "#f9e2af" : "#a6e3a1")

                                    Behavior on width {
                                        NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
                                    }
                                }
                            }

                            Text {
                                text: cpuStats.usage + "%"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                                color: "#cdd6f4"
                                Layout.preferredWidth: 35
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }

                // --- ROW 2: RAM PROGRESS METER ---
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "🧠 RAM"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        color: "#cdd6f4"
                        Layout.preferredWidth: 50
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 12
                        radius: 6
                        color: "#313244"

                        Rectangle {
                            width: parent.width * (ramStats.usage / 100)
                            height: parent.height
                            radius: 6
                            color: ramStats.usage > 85 ? "#f38ba8" : (ramStats.usage > 65 ? "#f9e2af" : "#b4befe")

                            Behavior on width {
                                NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
                            }
                        }
                    }

                    Text {
                        text: ramStats.usage + "%"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        color: "#cdd6f4"
                        Layout.preferredWidth: 35
                        horizontalAlignment: Text.AlignRight
                    }
                }

                // --- ROW 3: DISK PROGRESS METER ---
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "💾 DISK"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        color: "#cdd6f4"
                        Layout.preferredWidth: 50
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 12
                        radius: 6
                        color: "#313244"

                        Rectangle {
                            width: parent.width * (diskStats.usage / 100)
                            height: parent.height
                            radius: 6
                            color: diskStats.usage > 90 ? "#f38ba8" : (diskStats.usage > 75 ? "#f9e2af" : "#fab387")

                            Behavior on width {
                                NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
                            }
                        }
                    }

                    Text {
                        text: diskStats.usage + "%"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        color: "#cdd6f4"
                        Layout.preferredWidth: 35
                        horizontalAlignment: Text.AlignRight
                    }
                }

                // Resource footprint subtitles mapping details
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 60
                    spacing: 20

                    Text {
                        text: "RAM footprint: " + ramStats.textUsage
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        color: "#a6adc8"
                    }

                    Text {
                        text: "Disk footprint: " + diskStats.textUsage
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        color: "#a6adc8"
                    }
                }

                // --- THE POWER MENU FLYOUT ROW ---
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Layout.topMargin: 8

                    Text {
                        text: "System Session"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        color: "#a6adc8"
                    }

                    // Visual separator line
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: "#313244"
                    }

                    // Horizontal Grid of Action Buttons
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        // 1. LOCK SYSTEM BUTTON
                        Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            radius: 8
                            color: "#313244"

                            Text {
                                anchors.centerIn: parent
                                text: "🔒 Lock"
                                font.family: "JetBrainsMono Nerd Font"
                                color: "#cdd6f4"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.controlCenterOpen = false;
                                    Quickshell.execDetached(["sh", "-c", "xset dpms force off && i3lock -c 11111b"]);
                                }
                            }
                        }

                        // 2. SUSPEND / SLEEP BUTTON
                        Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            radius: 8
                            color: "#313244"

                            Text {
                                anchors.centerIn: parent
                                text: "💤 Sleep"
                                font.family: "JetBrainsMono Nerd Font"
                                color: "#cdd6f4"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.controlCenterOpen = false;
                                    Quickshell.execDetached(["systemctl", "suspend"]);
                                }
                            }
                        }

                        // 3. REBOOT BUTTON
                        Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            radius: 8
                            color: "#fab387"

                            Text {
                                anchors.centerIn: parent
                                text: "🔄 Reboot"
                                font.family: "JetBrainsMono Nerd Font"
                                color: "#11111b"
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.controlCenterOpen = false;
                                    Quickshell.execDetached(["systemctl", "reboot"]);
                                }
                            }
                        }

                        // 4. SHUTDOWN BUTTON
                        Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            radius: 8
                            color: "#f38ba8"

                            Text {
                                anchors.centerIn: parent
                                text: "🛑 Off"
                                font.family: "JetBrainsMono Nerd Font"
                                color: "#11111b"
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.controlCenterOpen = false;
                                    Quickshell.execDetached(["systemctl", "poweroff"]);
                                }
                            }
                        }
                    }
                } // End of Power Menu Row

                // FIXED BAR SEPARATOR: Pushes everything below to the absolute bottom of the container layout box
                Item {
                    Layout.fillHeight: true
                }

                // A clean, bottom-anchored close trigger with layout alignment separation
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: 8
                    color: "#1e1e2e"
                    border.color: "#313244"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Close Panel"
                        font.family: "JetBrainsMono Nerd Font"
                        color: "#a6adc8"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.controlCenterOpen = false
                    }
                }
            } // Closes ColumnLayout
        } // Closes the root dashboard visual Rectangle
   }
}
