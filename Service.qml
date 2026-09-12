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
  property real scaleFactor: 1.15

  readonly property real minScale: 0.75
  readonly property real maxScale: 1.60
  readonly property int edgePadding: Style.space(40)
  readonly property int topPadding: Style.space(72)

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

  function setScale(value) {
    root.scaleFactor = Math.max(root.minScale, Math.min(root.maxScale, Number(value)))
    root.saveSettings()
  }

  function saveSettings() {
    settingsFile.setText(JSON.stringify({
      placement: root.placement,
      visible: root.overlayVisible,
      scale: root.scaleFactor
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
      if (typeof parsed.scale === "number")
        root.scaleFactor = Math.max(root.minScale, Math.min(root.maxScale, parsed.scale))
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
      margins.left: root.placement.endsWith("left") ? root.edgePadding
        : root.placement.endsWith("right") ? modelData.width - implicitWidth - root.edgePadding
        : (modelData.width - implicitWidth) / 2
      margins.top: root.placement.startsWith("top") ? root.topPadding
        : root.placement.startsWith("bottom") ? modelData.height - implicitHeight - root.edgePadding
        : (modelData.height - implicitHeight) / 2
      implicitWidth: roster.implicitWidth * root.scaleFactor
      implicitHeight: roster.implicitHeight * root.scaleFactor
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
        scale: root.scaleFactor
        transformOrigin: Item.TopLeft

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
            textFormat: Text.PlainText
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

              Rectangle {
                id: avatarCircle
                anchors.fill: parent
                radius: width / 2
                color: Util.alpha(Color.popups.background, entry.modelData.speaking ? 0.9 : 0.65)

                Rectangle {
                  id: avatarMask
                  anchors.fill: parent
                  color: "white"
                  radius: width / 2
                  visible: false
                  layer.enabled: true
                }

                Item {
                  anchors.fill: parent
                  layer.enabled: true
                  layer.smooth: true
                  layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: avatarMask
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1.0
                  }

                  Image {
                    id: avatarImage
                    anchors.fill: parent
                    source: String(entry.modelData.avatar || "")
                    sourceSize: Qt.size(96, 96)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                  }
                }

                Text {
                  anchors.centerIn: parent
                  text: String(entry.modelData.initials || "?")
                  color: Color.popups.text
                  font.family: Style.font.family
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  textFormat: Text.PlainText
                  visible: !entry.modelData.avatar || avatarImage.status !== Image.Ready
                }
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
                textFormat: Text.PlainText
                elide: Text.ElideRight
              }
            }
          }
        }
      }
    }
  }
}
