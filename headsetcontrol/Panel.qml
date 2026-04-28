import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets

Item {
  id: root
  property var pluginApi: null
  property ShellScreen screen

  readonly property var mainInstance: pluginApi ? pluginApi.mainInstance : null
  readonly property var capabilities: mainInstance ? mainInstance.capabilities : ({})
  readonly property bool capabilitiesLoaded: mainInstance ? mainInstance.capabilitiesLoaded : false
  readonly property bool isConnected: mainInstance ? mainInstance.isConnected : false

  onPluginApiChanged: {
    Logger.i("HC Panel: pluginApi changed, exists=" + (pluginApi != null))
  }
  onMainInstanceChanged: {
    Logger.i("HC Panel: mainInstance set, exists=" + (mainInstance != null) + ", capabilitiesLoaded=" + (mainInstance ? mainInstance.capabilitiesLoaded : false))
    if (mainInstance) {
      // Trigger a full update when panel opens to ensure capabilities are fresh
      mainInstance.updateAll()
    }
  }
  onCapabilitiesLoadedChanged: {
    Logger.i("HC Panel: capabilitiesLoaded changed to " + capabilitiesLoaded)
    Logger.i("HC Panel: capabilities=" + JSON.stringify(capabilities))
  }
  readonly property int batteryLevel: mainInstance ? mainInstance.batteryLevel : -1
  readonly property string batteryStatus: mainInstance ? mainInstance.batteryStatus : "BATTERY_UNAVAILABLE"
  readonly property bool isCharging: batteryStatus === "BATTERY_CHARGING"
  readonly property bool batteryReady: root.isConnected && root.batteryLevel >= 0
  readonly property bool batteryLow: root.batteryLevel > 0 && root.batteryLevel < 20
  readonly property bool batteryCritical: root.batteryLevel >= 0 && root.batteryLevel < 10

  function sendCommand(args) {
    if (panelCmdProc.running) return
    panelCmdProc.command = ["/usr/bin/headsetcontrol"].concat(args)
    panelCmdProc.running = true
  }

  Process {
    id: panelCmdProc
    running: false
    stdout: StdioCollector { onStreamFinished: panelCmdProc.running = false }
    stderr: StdioCollector { onStreamFinished: if (text) Logger.w("HC panel: " + text) }
  }

  // Required for background rendering by PanelBackground
  readonly property var geometryPlaceholder: contentColumn

  // Panel dimensions
  property real contentPreferredWidth: 400 * Style.uiScaleRatio
  property real contentPreferredHeight: 700 * Style.uiScaleRatio

  ColumnLayout {
    id: contentColumn
    anchors.fill: parent
    anchors.margins: Style.marginL
    spacing: Style.marginM

    NText {
      text: "HeadsetControl"
      font.pixelSize: 16
      font.weight: Font.Bold
      color: Color.mOnSurface
    }

    Rectangle { Layout.fillWidth: true; height: 1; color: Color.mOutline ?? "#49454f" }

    NText {
      text: root.isConnected ? "Headset Connected" : "No Headset Detected"
      font.pixelSize: 13
      color: root.isConnected ? Color.mPrimary : Color.mOnSurfaceVariant
    }

    RowLayout {
      visible: root.batteryReady
      spacing: 8
      NBattery {
        percentage: Math.max(0, root.batteryLevel)
        charging: root.isCharging
        pluggedIn: root.isCharging
        ready: root.batteryReady
        low: root.batteryLow
        critical: root.batteryCritical
        baseSize: 13
        showPercentageText: true
      }
      NText {
        text: root.batteryStatus
        font.pixelSize: 11
        color: Color.mOnSurfaceVariant
      }
    }

    // Sidetone
    Rectangle { Layout.fillWidth: true; height: 1; color: Color.mOutline ?? "#49454f"; visible: root.isConnected && (root.capabilities["CAP_SIDETONE"] ?? false) }
    NText { text: "Sidetone"; visible: root.isConnected && (root.capabilities["CAP_SIDETONE"] ?? false); font.pixelSize: 13; color: Color.mOnSurface; font.weight: Font.Bold }
    RowLayout {
      visible: root.isConnected && (root.capabilities["CAP_SIDETONE"] ?? false); spacing: 6
      NSlider {
        id: sidetoneSlider; Layout.fillWidth: true; from: 0; to: 128; stepSize: 1
        value: pluginApi && pluginApi.pluginSettings ? pluginApi.pluginSettings.lastSidetone || 64 : 64
        onMoved: { root.sendCommand(["-s", String(value)]); if (pluginApi) pluginApi.pluginSettings.lastSidetone = Math.round(value) }
      }
      NText { text: Math.round(sidetoneSlider.value); font.pixelSize: 11; color: Color.mOnSurfaceVariant; Layout.minimumWidth: 30; horizontalAlignment: Text.AlignRight }
    }

    // Lights
    Rectangle { Layout.fillWidth: true; height: 1; color: Color.mOutline ?? "#49454f"; visible: root.isConnected && (root.capabilities["CAP_LIGHTS"] ?? false) }
    NText { text: "Lights"; visible: root.isConnected && (root.capabilities["CAP_LIGHTS"] ?? false); font.pixelSize: 13; color: Color.mOnSurface; font.weight: Font.Bold }
    RowLayout { visible: root.isConnected && (root.capabilities["CAP_LIGHTS"] ?? false); spacing: 8
      NButton { text: "On"; onClicked: root.sendCommand(["-l", "1"]) }
      NButton { text: "Off"; onClicked: root.sendCommand(["-l", "0"]) }
    }

    // Auto-Off Timer
    Rectangle { Layout.fillWidth: true; height: 1; color: Color.mOutline ?? "#49454f"; visible: root.isConnected && (root.capabilities["CAP_INACTIVE_TIME"] ?? false) }
    NText { text: "Auto-Off Timer (min)"; visible: root.isConnected && (root.capabilities["CAP_INACTIVE_TIME"] ?? false); font.pixelSize: 13; color: Color.mOnSurface; font.weight: Font.Bold }
    RowLayout { visible: root.isConnected && (root.capabilities["CAP_INACTIVE_TIME"] ?? false); spacing: 6
      NSlider { id: inactiveSlider; Layout.fillWidth: true; from: 0; to: 120; stepSize: 15; value: 30
        onMoved: root.sendCommand(["-i", String(value)]) }
      NText { text: Math.round(inactiveSlider.value); font.pixelSize: 11; color: Color.mOnSurfaceVariant; Layout.minimumWidth: 30; horizontalAlignment: Text.AlignRight }
    }

    // Equalizer Preset
    Rectangle { Layout.fillWidth: true; height: 1; color: Color.mOutline ?? "#49454f"; visible: root.isConnected && (root.capabilities["CAP_EQUALIZER_PRESET"] ?? false) }
    NText { text: "Equalizer Preset"; visible: root.isConnected && (root.capabilities["CAP_EQUALIZER_PRESET"] ?? false); font.pixelSize: 13; color: Color.mOnSurface; font.weight: Font.Bold }
    RowLayout { visible: root.isConnected && (root.capabilities["CAP_EQUALIZER_PRESET"] ?? false); spacing: 8
      NButton { text: "0"; onClicked: { root.sendCommand(["-p", "0"]); if (pluginApi) pluginApi.pluginSettings.lastEqPreset = 0 } }
      NButton { text: "1"; onClicked: { root.sendCommand(["-p", "1"]); if (pluginApi) pluginApi.pluginSettings.lastEqPreset = 1 } }
      NButton { text: "2"; onClicked: { root.sendCommand(["-p", "2"]); if (pluginApi) pluginApi.pluginSettings.lastEqPreset = 2 } }
      NButton { text: "3"; onClicked: { root.sendCommand(["-p", "3"]); if (pluginApi) pluginApi.pluginSettings.lastEqPreset = 3 } }
    }

    // Voice Prompts
    Rectangle { Layout.fillWidth: true; height: 1; color: Color.mOutline ?? "#49454f"; visible: root.isConnected && (root.capabilities["CAP_VOICE_PROMPTS"] ?? false) }
    NText { text: "Voice Prompts"; visible: root.isConnected && (root.capabilities["CAP_VOICE_PROMPTS"] ?? false); font.pixelSize: 13; color: Color.mOnSurface; font.weight: Font.Bold }
    RowLayout { visible: root.isConnected && (root.capabilities["CAP_VOICE_PROMPTS"] ?? false); spacing: 8
      NButton { text: "Enable"; onClicked: root.sendCommand(["-v", "1"]) }
      NButton { text: "Disable"; onClicked: root.sendCommand(["-v", "0"]) }
    }

    // Microphone LED Brightness
    Rectangle { Layout.fillWidth: true; height: 1; color: Color.mOutline ?? "#49454f"; visible: root.isConnected && (root.capabilities["CAP_MICROPHONE_MUTE_LED_BRIGHTNESS"] ?? false) }
    NText { text: "Microphone LED Brightness"; visible: root.isConnected && (root.capabilities["CAP_MICROPHONE_MUTE_LED_BRIGHTNESS"] ?? false); font.pixelSize: 13; color: Color.mOnSurface; font.weight: Font.Bold }
    RowLayout { visible: root.isConnected && (root.capabilities["CAP_MICROPHONE_MUTE_LED_BRIGHTNESS"] ?? false); spacing: 6
      NSlider { id: micLedSlider; Layout.fillWidth: true; from: 0; to: 3; stepSize: 1; value: 1
        onMoved: root.sendCommand(["--microphone-mute-led-brightness", String(value)]) }
      NText { text: Math.round(micLedSlider.value); font.pixelSize: 11; color: Color.mOnSurfaceVariant; Layout.minimumWidth: 30; horizontalAlignment: Text.AlignRight }
    }

    // Volume Limiter
    Rectangle { Layout.fillWidth: true; height: 1; color: Color.mOutline ?? "#49454f"; visible: root.isConnected && (root.capabilities["CAP_VOLUME_LIMITER"] ?? false) }
    NText { text: "Volume Limiter"; visible: root.isConnected && (root.capabilities["CAP_VOLUME_LIMITER"] ?? false); font.pixelSize: 13; color: Color.mOnSurface; font.weight: Font.Bold }
    RowLayout { visible: root.isConnected && (root.capabilities["CAP_VOLUME_LIMITER"] ?? false); spacing: 8
      NButton { text: "On"; onClicked: root.sendCommand(["--volume-limiter", "1"]) }
      NButton { text: "Off"; onClicked: root.sendCommand(["--volume-limiter", "0"]) }
    }

    // Chatmix
    Rectangle { Layout.fillWidth: true; height: 1; color: Color.mOutline ?? "#49454f"; visible: root.isConnected && (root.capabilities["CAP_CHATMIX_STATUS"] ?? false) }
    NText { text: "Chatmix"; visible: root.isConnected && (root.capabilities["CAP_CHATMIX_STATUS"] ?? false); font.pixelSize: 13; color: Color.mOnSurface; font.weight: Font.Bold }
    NText {
      visible: root.isConnected && (root.capabilities["CAP_CHATMIX_STATUS"] ?? false)
      font.pixelSize: 11; color: Color.mOnSurfaceVariant
      text: {
        if (!mainInstance) return "N/A"
        var lvl = mainInstance.chatmixLevel
        if (lvl < 0) return "N/A"
        return (lvl > 64 ? "Chat" : "Game") + " (" + lvl + ")"
      }
    }

    // Notification Sound
    Rectangle { Layout.fillWidth: true; height: 1; color: Color.mOutline ?? "#49454f"; visible: root.isConnected && (root.capabilities["CAP_NOTIFICATION_SOUND"] ?? false) }
    NText { text: "Notification Sound"; visible: root.isConnected && (root.capabilities["CAP_NOTIFICATION_SOUND"] ?? false); font.pixelSize: 13; color: Color.mOnSurface; font.weight: Font.Bold }
    RowLayout { visible: root.isConnected && (root.capabilities["CAP_NOTIFICATION_SOUND"] ?? false); spacing: 8
      NButton { text: "0"; onClicked: root.sendCommand(["-n", "0"]) }
      NButton { text: "1"; onClicked: root.sendCommand(["-n", "1"]) }
    }

    // Bluetooth
    Rectangle { Layout.fillWidth: true; height: 1; color: Color.mOutline ?? "#49454f"; visible: root.isConnected && (root.capabilities["CAP_BT_WHEN_POWERED_ON"] ?? false) }
    NText { text: "Bluetooth"; visible: root.isConnected && (root.capabilities["CAP_BT_WHEN_POWERED_ON"] ?? false); font.pixelSize: 13; color: Color.mOnSurface; font.weight: Font.Bold }
    RowLayout { visible: root.isConnected && (root.capabilities["CAP_BT_WHEN_POWERED_ON"] ?? false); spacing: 8
      NButton { text: "Power On: On"; onClicked: root.sendCommand(["--bt-when-powered-on", "1"]) }
      NButton { text: "Power On: Off"; onClicked: root.sendCommand(["--bt-when-powered-on", "0"]) }
    }
    RowLayout { visible: root.isConnected && (root.capabilities["CAP_BT_CALL_VOLUME"] ?? false); spacing: 6
      NText { text: "Call Volume"; font.pixelSize: 11; color: Color.mOnSurfaceVariant }
      NSlider { id: btVolSlider; Layout.fillWidth: true; from: 0; to: 100; stepSize: 1; value: 50
        onMoved: root.sendCommand(["--bt-call-volume", String(value)]) }
    }

    Rectangle { Layout.fillWidth: true; height: 1; color: Color.mOutline ?? "#49454f"; visible: root.isConnected }

    NButton {
      text: "Refresh Status"
      onClicked: {
        if (mainInstance) {
          mainInstance.updateAll()
        }
      }
      Layout.alignment: Qt.AlignHCenter
    }
  }
}
