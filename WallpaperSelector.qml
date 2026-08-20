import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: selectorRoot

    // Everything else flows down normally right into your properties:
    readonly property string rawWallpaperDir: "/home/toadwick/Pictures/wallhaven.cc"
    readonly property string wallpaperDirUrl: "file://" + rawWallpaperDir + "/"

    // --- FOCUS & ESCAPE KEY DISMISSAL TRACKER ---
    // Tells the inner QML layout graph that it can accept keyboard inputs
    focus: true

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            // Safely targets the wrapping PopupWindow directly and closes it!
            if (selectorRoot.parent && selectorRoot.parent.hasOwnProperty("visible")) {
                selectorRoot.parent.visible = false;
            }
            event.accepted = true; // Stop the keystroke event from leaking to bspwm
        }
    }
    // ============================================

    function setWallpaper(fileName) {
        let fullPath = rawWallpaperDir + "/" + fileName;
        Quickshell.execDetached(["feh", "--bg-fill", fullPath]);
    }

    Process {
        id: dirScanner
        command: ["find", selectorRoot.rawWallpaperDir, "-maxdepth", "1", "-type", "f", "-regextype", "egrep", "-iregex", ".*\\.(png|jpg|jpeg|webp)"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                wallpaperModel.clear();
                let output = text.trim();
                if (output.length === 0) return;
                let lines = output.split("\n");
                for (let i = 0; i < lines.length; i++) {
                    let fullPath = lines[i];
                    let fileName = fullPath.substring(fullPath.lastIndexOf("/") + 1);
                    let cleanName = fileName.replace(/\.[^/.]+$/, "").replace(/[-_]/g, " ");
                    cleanName = cleanName.replace(/\b\w/g, c => c.toUpperCase());
                    wallpaperModel.append({ "name": cleanName, "fileName": fileName });
                }
            }
        }
    }

    ListModel { id: wallpaperModel }

    // Wrap your styling cleanly inside a nice panel container background
    Rectangle {
        anchors.fill: parent
        color: "#1e1e2e"
        border.color: "#313244"
        border.width: 1
        radius: 8
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8 // Give it some clean padding
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4

            Text {
                text: "Select Wallpaper"
                font.pixelSize: 12
                font.bold: true
                color: "#a6adc8"
                Layout.fillWidth: true
            }

            Rectangle {
                implicitWidth: 20
                implicitHeight: 20
                radius: 4
                color: refreshArea.containsMouse ? "#313244" : "transparent"
                Text { anchors.centerIn: parent; color: "#dedede"; font.family: "Twemoji Mozilla"; text: "🗘"; font.pixelSize: 10 }
                MouseArea {
                    id: refreshArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: dirScanner.running = true;
                }
            }
        }

        // Horizontal scrolling gallery
        ScrollView {
            id: galleryScroll
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Crucial: Tell ScrollView to read the true pixel width of our inner Row
            contentWidth: rowItems.width

            ScrollBar.horizontal.policy: ScrollBar.AsNeeded
            ScrollBar.vertical.policy: ScrollBar.AlwaysOff

            Text {
                visible: wallpaperModel.count === 0
                text: "No wallpapers found in\n" + selectorRoot.rawWallpaperDir
                font.pixelSize: 11
                color: "#7f849c"
                horizontalAlignment: Text.AlignHCenter
                anchors.centerIn: parent
            }

            // Modern Wheel Interceptor
            WheelHandler {
                id: wheelHandler
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: (wheel) => {
                    if (wheel.angleDelta.y !== 0) {
                        // Scroll by 40 pixels per mouse tick
                        let step = (wheel.angleDelta.y / 120) * 40;
                        galleryScroll.ScrollBar.horizontal.position = Math.max(0,
                            Math.min(1.0 - galleryScroll.ScrollBar.horizontal.size,
                                     galleryScroll.ScrollBar.horizontal.position - (step / galleryScroll.contentWidth))
                        );
                    }
                }
            }

            // FIX: Using standard 'Row' instead of 'RowLayout' calculates dimensions perfectly for ScrollView
            Row {
                id: rowItems
                spacing: 8
                height: parent.height

                Repeater {
                    model: wallpaperModel
                    delegate: Rectangle {
                        id: thumbnailWrapper
                        implicitWidth: 180
                        implicitHeight: 130
                        radius: 4
                        color: "#181825"

                        border.color: thumbnailMouseArea.containsMouse ? "#f5c2e7" : "transparent"
                        border.width: 1.5
                        clip: true

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 1
                            anchors.margins: 1

                            Image {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                source: selectorRoot.wallpaperDirUrl + model.fileName
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: false
                                sourceSize.width: 160
                                sourceSize.height: 110
                            }

                            Text {
                                text: model.name
                                font.pixelSize: 9
                                color: "#cdd6f4"
                                Layout.alignment: Qt.AlignHCenter
                                elide: Text.ElideRight
                                Layout.maximumWidth: parent.width - 4
                            }
                        }

                        // UPDATED: Dual-click mouse tracking area
                        MouseArea {
                            id: thumbnailMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            z: 1

                            // Accept BOTH standard left clicks and contextual right clicks
                            acceptedButtons: Qt.LeftButton | Qt.RightButton

                            onClicked: (mouse) => {
                                if (mouse.button === Qt.LeftButton) {
                                    // Left click = Set the background wallpaper instantly
                                    setWallpaper(model.fileName);
                                } else if (mouse.button === Qt.RightButton) {
                                    // Right click = Safely route the image path up to our parent preview shield
                                    let targetUrl = selectorRoot.wallpaperDirUrl + model.fileName;

                                    // Looks up the component tree to trigger the custom overlay window
                                    if (typeof root.showPreviewPopup === "function") {
                                        root.showPreviewPopup(targetUrl);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
