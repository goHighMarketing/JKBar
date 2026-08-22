import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

MouseArea {
    id: layoutRoot

    // Explicit sizing for your bar layout
    implicitWidth: layoutRow.implicitWidth + 8
    implicitHeight: 24
    hoverEnabled: true
    // cursorShape: Qt.PointingHandCursor

    // Core state tracking property ("tiled" or "monocle")
    property string activeLayout: "tiled"

    // --- ASYNC STATE MONITOR ENGINE ---
    // Runs an open pipe listening to bspwm desktop event notifications live
    Process {
        id: bspwmListener
        command: ["bspc", "subscribe", "desktop"]
        running: true

        // FIX: Swapped to the correct Quickshell.Io component for line-by-line reading
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                // Trigger a fast configuration check whenever workspaces shift focus or alter layout trees
                queryLayout.running = true;
            }
        }
    }

    // Direct asynchronous hardware query runner
    Process {
        id: queryLayout
        command: ["sh", "-c", "bspc query -T -d | jq -r '.layout'"]
        running: true // Fire immediately on launch to cache our baseline layout state

        stdout: StdioCollector {
            onStreamFinished: {
                let layout = text.trim();
                if (layout === "tiled" || layout === "monocle") {
                    layoutRoot.activeLayout = layout;
                }
            }
        }
    }

    // --- INTERACTIVE CLICK TOGGLE CAPABILITY ---
    // Left-clicking toggles the current workspace layout state instantly via the hardware bus
    onClicked: {
        let nextLayout = (layoutRoot.activeLayout === "tiled") ? "monocle" : "tiled";
        Quickshell.execDetached(["bspc", "desktop", "-l", nextLayout]);

        // Optimistically update local state for instant visual feedback
        layoutRoot.activeLayout = nextLayout;
    }

    // Visual Presentation Layer
    RowLayout {
        id: layoutRow
        anchors.centerIn: parent
        spacing: 6

        // 1. DYNAMIC NERD FONT ICON INDICATOR
        Text {
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            Layout.alignment: Qt.AlignVCenter

            // Toggle icons and colors based on active workspace paradigm
            text: (layoutRoot.activeLayout === "tiled") ? "" : "🔲"
            color: (layoutRoot.activeLayout === "tiled") ? "#a6e3a1" : "#b4befe" // Pastel Green vs Lavender
        }

        // 2. TEXT DESCRIPTION READOUT
        Text {
            text: layoutRoot.activeLayout.toUpperCase()
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
            font.bold: true
            color: layoutRoot.hovered ? "#ffffff" : "#cdd6f4"
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
