import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: selectorRoot
    // FIX: Hard-code the dashboard dimensions so it doesn't crash the panel
    implicitWidth: 1850
    implicitHeight: 250

    readonly property string rawWallpaperDir: "/home/toadwick/Pictures/wallhaven.cc"
    readonly property string wallpaperDirUrl: "file://" + rawWallpaperDir + "/"

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
                Text { anchors.centerIn: parent; text: "🔄"; font.pixelSize: 10 }
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

                        // Safe property binding: Looks forward down to the mouse area ID below
                        border.color: thumbnailMouseArea.containsMouse ? "#f5c2e7" : "transparent"
                        border.width: 1.5
                        clip: true

                        // The visual contents
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

                        // FIX: MouseArea sits at the bottom with z: 1 so it handles clicks and hover,
                        // but doesn't shield the parent WheelHandler from mouse wheel spins
                        MouseArea {
                            id: thumbnailMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            z: 1
                            onClicked: setWallpaper(model.fileName);
                        }
                    }
                }
            }
        }
    }
}

