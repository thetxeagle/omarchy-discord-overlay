import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons

Item {
  id: root

  property var shell: null
  property var manifest: null
  readonly property string home: Quickshell.env("HOME")
  readonly property string settingsPath: home + "/.config/omarchy/discord-voice-overlay.json"
  readonly property string nameplatePath: home + "/.config/nameplate/config.json"

  property bool overlayVisible: true
  property string placement: "top-right"
  property var nameplateSettings: ({})
  property string channelName: "Not in a voice channel"
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
    root.saveNameplateConfig()
  }

  function toggle() {
    root.overlayVisible = !root.overlayVisible
    root.saveSettings()
    root.saveNameplateConfig()
  }

  function setVisible(value) {
    root.overlayVisible = !!value
    root.saveSettings()
    root.saveNameplateConfig()
  }

  function loadNameplate(raw) {
    try {
      var parsed = JSON.parse(raw)
      if (!parsed || typeof parsed !== "object") throw new Error("not an object")
      root.nameplateSettings = parsed
      if (root.placements.indexOf(parsed.anchor) >= 0)
        root.placement = parsed.anchor
      if (typeof parsed.visible === "boolean")
        root.overlayVisible = parsed.visible
    } catch (error) {
      // Nameplate owns the file format; defaults remain usable if it is absent.
    }
  }

  function loadSettings(raw) {
    try {
      var parsed = JSON.parse(raw)
      if (!parsed || typeof parsed !== "object") return
      if (root.placements.indexOf(parsed.placement) >= 0)
        root.placement = parsed.placement
      if (typeof parsed.visible === "boolean") root.overlayVisible = parsed.visible
    } catch (error) {
      // Defaults are intentional when the settings file is missing or corrupt.
    }
  }

  function saveSettings() {
    settingsFile.setText(JSON.stringify({
      placement: root.placement,
      visible: root.overlayVisible
    }, null, 2) + "\n")
  }

  function saveNameplateConfig() {
    var config = JSON.parse(JSON.stringify(root.nameplateSettings || {}))
    config.anchor = root.placement
    config.visible = root.overlayVisible
    nameplateFile.setText(JSON.stringify(config, null, 2) + "\n")
  }

  FileView {
    id: nameplateFile
    path: root.nameplatePath
    watchChanges: true
    printErrors: false
    onLoaded: root.loadNameplate(text())
    onFileChanged: reload()
  }

  FileView {
    id: settingsFile
    path: root.settingsPath
    atomicWrites: true
    printErrors: false
    onLoaded: root.loadSettings(text())
  }

}
