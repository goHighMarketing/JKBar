import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

RowLayout {
    id: brightnessRoot
    spacing: 12

    // Core property to hold the active percentage (0.0 to 1.0)
    property real brightnessLevel: 0.5

    // Asynchronous engine to pull current system screen status on creation
    Process {
        id: getBrightness
        command: ["brightnessctl", "g"] // 'g' gets current raw value
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let current = parseFloat(text.trim());
                getMaxBrightness.currentRaw = current;
                getMaxBrightness.running = true; // Trigger max capacity check next
            }
        }
    }

    Process {
        id: getMaxBrightness
        property real currentRaw: 0
        command: ["brightnessctl", "m"] // 'm' gets max raw value
        stdout: StdioCollector {
            onStreamFinished: {
                let max = parseFloat(text.trim());
                if (max > 0) {
                    brightnessRoot.brightnessLevel = getMaxBrightness.currentRaw / max;
                }
            }
        }
    }

    // Dynamic Icon Indicator
    Text {
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 16
        color: "#f9e2af" // Catppuccin Pastel Yellow
        Layout.alignment: Qt.AlignVCenter

        // Switch glyph appearance smoothly based on current light saturation
        text: {
            if (brightnessRoot.brightnessLevel < 0.3) return "  "; // Low
            if (brightnessRoot.brightnessLevel < 0.7) return "  "; // Medium
            return "  "; // Full Brightness
        }
    }

    // High-Fidelity Interaction Slider Track
    Slider {
        id: brightnessSlider
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter

        from: 0.05 // Cap low bound at 5% so your screen never goes completely black!
        to: 1.0
        value: brightnessRoot.brightnessLevel

        // Handle active sliding movements instantly
        onMoved: {
            brightnessRoot.brightnessLevel = value;
            let percentValue = Math.round(value * 100);

            // Fires an unblocked hardware execution instruction straight to your display device
            Quickshell.execDetached(["brightnessctl", "s", percentValue + "%"]);
        }

        // Custom Styling matching your premium dark aesthetics
        background: Rectangle {
            x: brightnessSlider.leftPadding
            y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
            implicitWidth: 200
            implicitHeight: 4
            width: brightnessSlider.availableWidth
            height: implicitHeight
            radius: 2
            color: "#313244" // Track background channel line

            Rectangle {
                width: brightnessSlider.visualPosition * parent.width
                height: parent.height
                color: "#f9e2af" // Active filled track line
                radius: 2
            }
        }

        handle: Rectangle {
            x: brightnessSlider.leftPadding + brightnessSlider.visualPosition * (brightnessSlider.availableWidth - width)
            y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
            implicitWidth: 12
            implicitHeight: 12
            radius: 6
            color: brightnessSlider.hovered ? "#ffe599" : "#f9e2af"
            border.color: "#11111b"
            border.width: 1
        }
    }

    // Visual Percentage Text Readout
    Text {
        text: Math.round(brightnessRoot.brightnessLevel * 100) + "%"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
        font.bold: true
        color: "#cdd6f4"
        width: 35
        horizontalAlignment: Text.AlignRight
        Layout.alignment: Qt.AlignVCenter
    }
}
