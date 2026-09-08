import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "eagle.discord-voice-overlay"

  readonly property var service: bar && bar.shell ? bar.shell.serviceFor("eagle.discord-voice-overlay") : null
  readonly property bool opened: popupOpen
  property bool popupOpen: false

  function togglePopup() { popupOpen = !popupOpen }
  function close() { popupOpen = false }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.service && root.service.overlayVisible ? "󰙯" : "󰙯̸"
    slotSize: Style.bar.statusSlot
    tooltipText: root.service && root.service.overlayVisible ? "Discord voice overlay · on" : "Discord voice overlay · hidden"
    onPressed: root.togglePopup()
  }

  KeyboardPanel {
    id: popup
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: Style.space(318)
    contentHeight: popup.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
    }

    Column {
      id: content
      anchors.fill: parent
      anchors.margins: Style.space(12)
      spacing: Style.space(12)

      Text {
        text: "DISCORD VOICE OVERLAY"
        color: Color.popups.text
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
        font.letterSpacing: 1.2
      }

      RowLayout {
        width: parent.width
        Text {
          Layout.fillWidth: true
          text: root.service && root.service.overlayVisible ? "Overlay visible" : "Overlay hidden"
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
        }
        Button {
          text: root.service && root.service.overlayVisible ? "Hide" : "Show"
          foreground: Color.popups.text
          onClicked: if (root.service) root.service.toggle()
        }
      }

      Text {
        text: "PLACEMENT"
        color: Color.popups.text
        opacity: 0.58
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.letterSpacing: 1.1
      }

      Grid {
        columns: 3
        rows: 3
        spacing: Style.space(6)
        anchors.horizontalCenter: parent.horizontalCenter

        Repeater {
          model: root.service ? root.service.placements : []
          delegate: Rectangle {
            width: Style.space(82)
            height: Style.space(42)
            radius: Style.cornerRadius
            color: modelData === (root.service ? root.service.placement : "") ? Color.accent : Util.alpha(Color.popups.text, 0.08)
            border.color: Util.alpha(Color.popups.text, 0.18)
            border.width: 1

            Text {
              anchors.centerIn: parent
              text: ["↖", "↑", "↗", "←", "•", "→", "↙", "↓", "↘"][index]
              color: modelData === (root.service ? root.service.placement : "") ? Color.background : Color.popups.text
              font.family: Style.font.family
              font.pixelSize: Style.font.body
            }
            MouseArea {
              anchors.fill: parent
              onClicked: if (root.service) root.service.setPlacement(modelData)
            }
          }
        }
      }

      Text {
        width: parent.width
        wrapMode: Text.WordWrap
        text: "Placement is controlled here. The overlay itself stays out of the way of your game input."
        color: Color.popups.text
        opacity: 0.58
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
    }
  }
}
