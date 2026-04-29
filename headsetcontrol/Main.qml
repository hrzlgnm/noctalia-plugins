import QtQuick
import Quickshell.Io
import QtQuick.Window 2.15
import qs.Commons

Item {
  id: root
  property var pluginApi: null

  property int batteryLevel: -1
  property string batteryStatus: "BATTERY_UNAVAILABLE"
  property bool isConnected: false
  readonly property bool isCharging: batteryStatus === "BATTERY_CHARGING"
  property string deviceName: ""
  property int chatmixLevel: -1
  property var capabilities: ({})
  property bool capabilitiesLoaded: false
  property int pollingInterval: 30

  onPluginApiChanged: {
    if (pluginApi && pluginApi.pluginSettings)
      pollingInterval = pluginApi.pluginSettings.pollingInterval || 30
  }

  property string _rawOutput: ""
  property bool _parseFull: false

  function parseJsonOutput(data, full) {
    try {
      var json = JSON.parse(data)
      if (!json || !json.devices || json.devices.length === 0) {
        root.isConnected = false
        root.capabilities = {}
        root.capabilitiesLoaded = false
        root.batteryLevel = -1
        root.batteryStatus = "BATTERY_UNAVAILABLE"
        root.chatmixLevel = -1
        root.deviceName = ""
        return
      }
      var dev = json.devices[0]
      var batteryUnavailable = !dev.battery || dev.battery.status === "BATTERY_UNAVAILABLE"
      if (batteryUnavailable) {
        root.isConnected = false
        root.capabilities = {}
        root.capabilitiesLoaded = false
        root.batteryLevel = -1
        root.batteryStatus = "BATTERY_UNAVAILABLE"
        root.chatmixLevel = -1
        root.deviceName = ""
        return
      }
      root.isConnected = true
        root.deviceName = dev.device_name || ""
        if (full) {
        var caps = {}
        if (dev.capabilities) {
          for (var j = 0; j < dev.capabilities.length; j++)
            caps[dev.capabilities[j]] = true
        }
        root.capabilities = caps
        root.capabilitiesLoaded = true
      }
      if (dev.battery) {
        root.batteryLevel = dev.battery.level >= 0 ? dev.battery.level : -1
        root.batteryStatus = dev.battery.status || "BATTERY_UNAVAILABLE"
      }
      if (dev.chatmix !== undefined)
        root.chatmixLevel = dev.chatmix
    } catch(e) {
      Logger.e("HeadsetControl: parse error:", e)
    }
  }

  Process {
    id: queryProc
    running: false
    stdout: StdioCollector {
      id: outCollector
      onStreamFinished: {
        if (outCollector.text) {
          root._rawOutput = outCollector.text
        }
      }
    }
    stderr: StdioCollector {
      id: errCollector
      onStreamFinished: {
        if (errCollector.text) Logger.w("HC: stderr=" + errCollector.text)
      }
    }
  }

  Process {
    id: simpleProc
    running: false
    stdout: StdioCollector { onStreamFinished: this.parent.running = false }
    stderr: StdioCollector { }
  }

  function updateAll() {
    _parseFull = true
    queryProc.command = ["/usr/bin/headsetcontrol", "-o", "json"]
    queryProc.running = true
  }

  function updateBatteryChatmix() {
    _parseFull = false
    queryProc.command = ["/usr/bin/headsetcontrol", "-o", "json"]
    queryProc.running = true
  }

  function callSimple(args) {
    if (simpleProc.running) return
    simpleProc.command = ["/usr/bin/headsetcontrol"].concat(args)
    simpleProc.running = true
  }

  on_RawOutputChanged: {
    if (_rawOutput) {
      parseJsonOutput(_rawOutput, _parseFull)
      _rawOutput = ""
    }
  }

  Timer {
    id: pollTimer
    interval: root.pollingInterval * 1000
    running: root.pollingInterval > 0
    repeat: true
    onTriggered: root.updateBatteryChatmix()
  }

  Timer {
    id: initTimer
    interval: 3000
    running: true
    repeat: false
    onTriggered: root.updateAll()
  }

  onPollingIntervalChanged: pollTimer.interval = root.pollingInterval * 1000

  IpcHandler {
    target: "plugin:headsetcontrol"

    function setSidetone(level: string) {
      var lvl = parseInt(level)
      if (isNaN(lvl) || lvl < 0 || lvl > 128) return JSON.stringify({error: "Level must be 0-128"})
      if (root.pluginApi) root.pluginApi.pluginSettings.lastSidetone = lvl
      root.callSimple(["-s", String(lvl)])
      return JSON.stringify({success: true, level: lvl})
    }

    function setLights(on: string) {
      var val = (on === "1" || on === "true") ? "1" : "0"
      root.callSimple(["-l", val])
      return JSON.stringify({success: true, lights: val === "1"})
    }

    function setInactiveTime(minutes: string) {
      var min = parseInt(minutes)
      if (isNaN(min) || min < 0) return JSON.stringify({error: "Minutes must be >= 0"})
      root.callSimple(["-i", String(min)])
      return JSON.stringify({success: true, minutes: min})
    }

    function setVoicePrompt(on: string) {
      var val = (on === "1" || on === "true") ? "1" : "0"
      root.callSimple(["-v", val])
      return JSON.stringify({success: true, voicePrompt: val === "1"})
    }

    function setEqualizerPreset(preset: string) {
      var p = parseInt(preset)
      if (isNaN(p) || p < 0 || p > 3) return JSON.stringify({error: "Preset must be 0-3"})
      if (root.pluginApi) root.pluginApi.pluginSettings.lastEqPreset = p
      root.callSimple(["-p", String(p)])
      return JSON.stringify({success: true, preset: p})
    }

    function setEqualizer(curve: string) {
      root.callSimple(["-e", curve])
      return JSON.stringify({success: true})
    }

    function setMicMuteLedBrightness(level: string) {
      var lvl = parseInt(level)
      if (isNaN(lvl)) return JSON.stringify({error: "Invalid brightness level"})
      root.callSimple(["--microphone-mute-led-brightness", String(lvl)])
      return JSON.stringify({success: true, level: lvl})
    }

    function setVolumeLimiter(on: string) {
      var val = (on === "1" || on === "true") ? "1" : "0"
      root.callSimple(["--volume-limiter", val])
      return JSON.stringify({success: true, limiter: val === "1"})
    }

    function setBtPowerOn(on: string) {
      var val = (on === "1" || on === "true") ? "1" : "0"
      root.callSimple(["--bt-when-powered-on", val])
      return JSON.stringify({success: true, btPowerOn: val === "1"})
    }

    function setBtCallVolume(volume: string) {
      var vol = parseInt(volume)
      if (isNaN(vol)) return JSON.stringify({error: "Invalid volume"})
      root.callSimple(["--bt-call-volume", String(vol)])
      return JSON.stringify({success: true, volume: vol})
    }

    function sendNotification(type: string) {
      var t = type || "0"
      root.callSimple(["-n", t])
      return JSON.stringify({success: true, type: t})
    }

    function checkConnected() {
      return JSON.stringify({connected: root.isConnected})
    }

    function togglePanel() {
      if (!root.pluginApi) return
      root.pluginApi.withCurrentScreen(function(s) { root.pluginApi.togglePanel(s) })
    }
  }
}
