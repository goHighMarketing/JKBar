// BulletproofWorkspaces.qml
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // Raw list of all workspaces
    property var workspaces: []

    // The Filtered List: Dynamically exposes ONLY occupied, urgent, or the CURRENTLY focused workspace
    property var occupiedWorkspaces: {
        let filtered = [];
        for (let i = 0; i < workspaces.length; i++) {
            let ws = workspaces[i];
            if (ws.isFocused || ws.isOccupied || ws.isUrgent) {
                filtered.push(ws);
            }
        }
        return filtered;
    }

    // Continually streams BSPWM desktop states
    property Process bspcProcess: Process {
        running: true
        command: ["bspc", "subscribe", "report"]

        stdout: SplitParser {
            onRead: (data) => {
                let report = data.toString().trim();
                if (!report.startsWith("W")) return;

                let parsedWorkspaces = [];
                let items = report.split(":");
                
                for (let i = 1; i < items.length; i++) {
                    let item = items[i];
                    if (item.length < 2) continue;

                    let stateChar = item[0];
                    let name = item.substring(1);

                    // Skip monitor names and layout flags
                    if ("MmGgLkTt".includes(stateChar)) {
                        continue;
                    }

                    // Strict BSPWM mapping:
                    // Uppercase (F, O, U) = Focused/Active desktop
                    // Lowercase (f, o, u) = Unfocused desktop
                    let isFocused = "FOU".includes(stateChar);
                    let isOccupied = (stateChar === 'o' || stateChar === 'O');
                    let isUrgent = (stateChar === 'u' || stateChar === 'U');

                    // Only push actual workspaces to our list
                    if ("fFoOuU".includes(stateChar)) {
                        parsedWorkspaces.push({
                            name: name,
                            isFocused: isFocused,
                            isOccupied: isOccupied,
                            isUrgent: isUrgent
                        });
                    }
                }
                root.workspaces = parsedWorkspaces;
            }
        }
    }
}