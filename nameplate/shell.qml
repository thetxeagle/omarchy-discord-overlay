import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    property bool inVoice: false
    property var users: []
    property string channelName: ""

    readonly property string configPath:
        (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config")
        + "/nameplate/config.json"

    FileView {
        path: root.configPath
        watchChanges: true
        onFileChanged: reload()
        // First run: drop a config file with the defaults in it.
        onLoadFailed: writeAdapter()

        adapter: JsonAdapter {
            id: config

            // top-left, top-right, bottom-left or bottom-right
            property string anchor: "top-left"
            property bool visible: true
            // Distance from the anchored corner. marginY clears a bar.
            property int marginX: 15
            property int marginY: 50
            property int avatarSize: 24
            property int fontSize: 12
            property int rowSpacing: 6
            // Keep yourself at the top of the list rather than in name order.
            property bool selfFirst: true
            property string accent: "#bc9afa"
            property string fontFamily: "Archivo"
        }
    }

    readonly property color accent: config.accent
    readonly property int avatarSize: config.avatarSize
    readonly property int fontSize: config.fontSize
    readonly property bool atTop: config.anchor.startsWith("top")
    readonly property bool atBottom: config.anchor.startsWith("bottom")
    readonly property bool atLeft: config.anchor.endsWith("left")
    readonly property bool atRight: config.anchor.endsWith("right")
    readonly property var ordered: config.selfFirst
        ? users.slice().sort((a, b) => (b.self ? 1 : 0) - (a.self ? 1 : 0))
        : users

    Process {
        command: ["nameplate-bridge"]
        running: true

        stdout: SplitParser {
            onRead: line => {
                if (!line.trim()) return
                const state = JSON.parse(line)
                root.users = state.users
                root.channelName = state.channel || ""
                root.inVoice = state.in_voice && state.users.length > 0
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            anchors.top: true
            anchors.left: true
            margins.left: root.atLeft ? config.marginX
                : root.atRight ? modelData.width - implicitWidth - config.marginX
                : (modelData.width - implicitWidth) / 2
            margins.top: root.atTop ? config.marginY
                : root.atBottom ? modelData.height - implicitHeight - config.marginY
                : (modelData.height - implicitHeight) / 2

            implicitWidth: column.implicitWidth
            implicitHeight: column.implicitHeight
            visible: config.visible && root.inVoice
            color: "transparent"

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "nameplate"

            // Empty input region: clicks fall through to the game underneath.
            mask: Region {}

        Column {
            id: column
            spacing: config.rowSpacing

            Rectangle {
                visible: root.channelName.length > 0
                implicitWidth: channelLabel.implicitWidth + 16
                implicitHeight: channelLabel.implicitHeight + 6
                radius: height / 2
                color: Qt.rgba(0, 0, 0, 0.45)

                Text {
                    id: channelLabel
                    anchors.centerIn: parent
                    text: root.channelName
                    color: Qt.rgba(1, 1, 1, 0.78)
                    font.family: config.fontFamily
                    font.pixelSize: root.fontSize
                    font.bold: true
                    elide: Text.ElideRight
                }
            }

            Repeater {
                model: root.ordered

                Row {
                    id: entry
                    required property var modelData
                    readonly property bool speaking: modelData.speaking
                    readonly property bool silenced: modelData.mute || modelData.deaf

                    spacing: 6

                    Item {
                        width: root.avatarSize
                        height: root.avatarSize
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            id: source
                            anchors.fill: parent
                            source: entry.modelData.avatar
                            sourceSize: Qt.size(root.avatarSize * 3, root.avatarSize * 3)
                            asynchronous: true
                            visible: false
                        }

                        Rectangle {
                            id: circle
                            anchors.fill: parent
                            radius: width / 2
                            visible: false
                            layer.enabled: true
                        }

                        MultiEffect {
                            anchors.fill: parent
                            source: source
                            maskEnabled: true
                            maskSource: circle
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1.0
                            saturation: entry.silenced ? -1.0 : 0.0
                            opacity: entry.speaking ? 1.0 : 0.75

                            Behavior on opacity { NumberAnimation { duration: 100 } }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: "transparent"
                            border.width: 2
                            border.color: entry.speaking ? root.accent : "transparent"

                            Behavior on border.color { ColorAnimation { duration: 100 } }
                        }
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: label.implicitWidth + 16
                        implicitHeight: label.implicitHeight + 6
                        radius: height / 2
                        color: Qt.rgba(0, 0, 0, entry.speaking ? 1.0 : 0.45)

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Row {
                            id: label
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: entry.modelData.name
                                color: entry.speaking ? "#ffffff" : Qt.rgba(1, 1, 1, 0.65)
                                font.family: config.fontFamily
                                font.pixelSize: root.fontSize

                                Behavior on color { ColorAnimation { duration: 100 } }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: entry.silenced
                                text: entry.modelData.deaf ? "\u{f0e08}" : "\u{f036c}"
                                color: "#ff6b6b"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: root.fontSize
                            }
                        }
                    }
                }
            }
        }
        }
    }
}
