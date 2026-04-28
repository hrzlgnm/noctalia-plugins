import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

Item {
  id: root
  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  readonly property string screenName: screen?.name ?? ""
  readonly property real barFontSize: 14

  readonly property real contentWidth: content.implicitWidth + 8 * 2
  readonly property real contentHeight: 32

  implicitWidth: contentWidth
  implicitHeight: contentHeight

  readonly property int batteryLevel: pluginApi && pluginApi.mainInstance ? pluginApi.mainInstance.batteryLevel : -1
  readonly property bool isConnected: pluginApi && pluginApi.mainInstance ? pluginApi.mainInstance.isConnected : false
  readonly property bool isCharging: pluginApi && pluginApi.mainInstance ? pluginApi.mainInstance.isCharging : false
  readonly property bool showPercentage: pluginApi && pluginApi.pluginSettings ? pluginApi.pluginSettings.barShowPercentage !== false : true

  readonly property bool batteryReady: root.isConnected && root.batteryLevel >= 0
  readonly property bool batteryLow: root.batteryLevel > 0 && root.batteryLevel < 20
  readonly property bool batteryCritical: root.batteryLevel >= 0 && root.batteryLevel < 10

  Rectangle {
    id: visualCapsule
    anchors.fill: parent
    color: mouseArea.containsMouse ? Qt.rgba(1,1,1,0.1) : Qt.rgba(1,1,1,0.05)
    radius: 8
    border.color: Qt.rgba(1,1,1,0.1)
    border.width: 1

    RowLayout {
      id: content
      anchors.centerIn: parent
      spacing: 6

      NIcon {
        icon: root.isConnected ? "headset" : "headset-off"
        width: root.barFontSize
        height: root.barFontSize
        color: root.isConnected ? Color.mOnSurface : Qt.rgba(1,1,1,0.4)
      }

       NBattery {
         visible: root.showPercentage && root.isConnected
        percentage: Math.max(0, root.batteryLevel)
        charging: root.isCharging
        pluggedIn: root.isCharging
        ready: root.batteryReady
        low: root.batteryLow
        critical: root.batteryCritical
        baseSize: root.barFontSize * 0.82
        showPercentageText: true
        opacity: root.batteryReady ? 1.0 : 0.5
      }

      NText {
        text: "N/A"
        font.pixelSize: root.barFontSize * 0.82
        color: Qt.rgba(1,1,1,0.4)
        visible: !root.showPercentage && !root.isConnected
        Layout.alignment: Qt.AlignVCenter
      }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      if (pluginApi) pluginApi.togglePanel(root.screen)
    }
  }
}
