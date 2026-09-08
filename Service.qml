import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons

Item {
  id: root

  property var shell: null
  property var manifest: null
  readonly property string home: Quickshell.env("HOME")
  readonly property string pluginPath: home + "/.config/omarchy/plugins/eagle.discord-voice-overlay"
  readonly property string settingsPath: home + "/.config/omarchy/discord-voice-overlay.json"

  property bool overlayVisible: true
  property string placement: "top-right"
  property string channelName: ""
  property var members: []
  property string dataState: "waiting"

  readonly property var placements: [
    "top-left", "top-center", "top-right",
    "middle-left", "center", "middle-right",
    "bottom-left", "bottom-center", "bottom-right"
  ]

  function setPlacement(value) {
    if (root.placements.indexOf(value) < 0) return
    root.placement = value
    root.saveSettings()
  }

  function toggle() {
    root.overlayVisible = !root.overlayVisible
    root.saveSettings()
  }

  function setVisible(value) {
    root.overlayVisible = !!value
    root.saveSettings()
  }

  function saveSettings() {
    settingsFile.setText(JSON.stringify({
      placement: root.placement,
      visible: root.overlayVisible
    }, null, 2) + "\n")
  }

  function loadSettings(raw) {
    try {
      var parsed = JSON.parse(raw)
      if (!parsed || typeof parsed !== "object") return
      if (root.placements.indexOf(parsed.placement) >= 0)
        root.placement = parsed.placement
      if (typeof parsed.visible === "boolean")
        root.overlayVisible = parsed.visible
    } catch (error) {
      // Defaults are intentional when the settings file is missing or corrupt.
    }
  }

  function loadBridgeLine(raw) {
    try {
      var parsed = JSON.parse(raw)
      root.channelName = String(parsed.channel || "")
      root.members = Array.isArray(parsed.users) ? parsed.users : []
      root.dataState = "live"
    } catch (error) {
      root.channelName = ""
      root.members = []
      root.dataState = "invalid"
    }
  }

  FileView {
    id: settingsFile
    path: root.settingsPath
    atomicWrites: true
    printErrors: false
    onLoaded: root.loadSettings(text())
  }

  Process {
    command: [root.pluginPath + "/nameplate-bridge"]
    running: true

    stdout: SplitParser {
      onRead: line => {
        if (line.trim()) root.loadBridgeLine(line)
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
      margins.left: root.placement.endsWith("left") ? Style.space(24)
        : root.placement.endsWith("right") ? modelData.width - implicitWidth - Style.space(24)
        : (modelData.width - implicitWidth) / 2
      margins.top: root.placement.startsWith("top") ? Style.space(50)
        : root.placement.startsWith("bottom") ? modelData.height - implicitHeight - Style.space(24)
        : (modelData.height - implicitHeight) / 2
      implicitWidth: roster.implicitWidth
      implicitHeight: roster.implicitHeight
      visible: root.overlayVisible && root.members.length > 0
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "eagle-discord-voice-overlay"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

      mask: Region {}

      Column {
        id: roster
        spacing: Style.space(6)

        Rectangle {
          visible: root.channelName.length > 0
          implicitWidth: channelLabel.implicitWidth + Style.space(18)
          implicitHeight: channelLabel.implicitHeight + Style.space(8)
          radius: height / 2
          color: Util.alpha(Color.popups.background, 0.72)

          Text {
            id: channelLabel
            anchors.centerIn: parent
            text: root.channelName
            color: Color.popups.text
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            font.bold: true
            elide: Text.ElideRight
          }
        }

        Repeater {
          model: root.members

          delegate: Row {
            id: entry
            required property var modelData
            spacing: Style.space(7)

            Item {
              width: Style.space(26)
              height: width

              Image {
                id: avatar
                anchors.fill: parent
                source: entry.modelData.avatar || ""
                sourceSize: Qt.size(78, 78)
                asynchronous: true
                visible: false
              }

              Rectangle {
                id: avatarMask
                anchors.fill: parent
                radius: width / 2
                visible: false
                layer.enabled: true
              }

              MultiEffect {
                anchors.fill: parent
                source: avatar
                maskEnabled: true
                maskSource: avatarMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
                opacity: entry.modelData.speaking ? 1.0 : 0.72
                saturation: entry.modelData.mute || entry.modelData.deaf ? -1.0 : 0.0
              }

              Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: entry.modelData.speaking ? "#57F287" : "transparent"
              }
            }

            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              implicitWidth: label.implicitWidth + Style.space(16)
              implicitHeight: label.implicitHeight + Style.space(6)
              radius: height / 2
              color: Util.alpha(Color.popups.background, entry.modelData.speaking ? 0.88 : 0.55)

              Text {
                id: label
                anchors.centerIn: parent
                text: String(entry.modelData.name || "Unknown")
                  + (entry.modelData.mute || entry.modelData.deaf ? " 󰍭" : "")
                color: entry.modelData.speaking ? Color.popups.text : Util.alpha(Color.popups.text, 0.72)
                font.family: Style.font.family
                font.pixelSize: Style.font.bodySmall
                font.bold: entry.modelData.speaking
                elide: Text.ElideRight
              }
            }
          }
        }
      }
    }
  }
}
