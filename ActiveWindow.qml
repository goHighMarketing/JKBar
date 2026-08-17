import QtQuick
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

RowLayout {
    id: activeWindowRoot

    property string windowTitle: ""

    Process {
        id: xdotoolStream
        // We spin up a lightweight bash stream loop to continuously listen for focus changes
        command: [
            "bash", "-c",
            "xprop -root -spy _NET_ACTIVE_WINDOW | while read -r _; do " +
            "  wid=$(xdotool getactivewindow 2>/dev/null); " +
            "  if [ -n \"$wid\" ]; then " +
            "    xdotool getwindowname \"$wid\" 2>/dev/null; " +
            "  else " +
            "    echo \"\"; " +
            "  fi; " +
            "done"
        ]
        running: true

        // We switch from SplitParser to StdioCollector or LineParser to update strings instantly per newline
        stdout: SplitParser {
            onRead: (data) => {
                activeWindowRoot.windowTitle = data.toString().trim();
            }
        }
    }

    Text {
        id: titleText
        text: activeWindowRoot.windowTitle !== "" ? activeWindowRoot.windowTitle : "Desktop"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
        font.weight: Font.Medium
        color: "#a9b1d6"

        elide: Text.ElideRight
        width: contentWidth > 400 ? 400 : contentWidth
    }
}
