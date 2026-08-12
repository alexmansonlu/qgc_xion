/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.Palette

// [ACULA GCS] Controller (遙控器) page — v0.2.2 redesign.
//
// The ACULA handheld controller uplinks pilot input exclusively as MAVLink
// RC_CHANNELS_OVERRIDE with a fixed, self-scaled channel map (JoystickUsbHid).
// QGC's stock joystick machinery (calibration wizard, expo, axis functions,
// MANUAL_CONTROL) is not used, so this page intentionally shows only what is
// real for this product:
//   - controller connection status
//   - the RC output enable switch
//   - a live monitor: raw controls in → remapped RC channel values out
//
// The stock Vehicle Setup → Joystick page is hidden (SetupView.qml) and
// MANUAL_CONTROL is suppressed product-wide (Joystick::suppressManualControl).

SettingsPage {
    id: root

    property var  _activeJoystick: joystickManager.activeJoystick
    property var  _activeVehicle:  QGroundControl.multiVehicleManager.activeVehicle
    property bool _connected:      _activeJoystick !== null

    QGCPalette { id: qgcPal }

    Component.onCompleted: if (_connected) _activeJoystick.startRawMonitoring()
    Component.onDestruction: if (_connected) _activeJoystick.stopRawMonitoring()

    Connections {
        target: joystickManager
        function onActiveJoystickChanged() {
            if (root._connected) {
                root._activeJoystick.startRawMonitoring()
            }
        }
    }

    //-------------------------------------------------------------------------
    //-- Connection status
    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Controller")

        QGCLabel {
            Layout.fillWidth:   true
            wrapMode:           Text.WordWrap
            color:              qgcPal.warningText
            visible:            !root._connected
            text:               qsTr("No controller detected — connect the handheld controller over USB.")
        }

        LabelledLabel {
            Layout.fillWidth:   true
            visible:            root._connected
            label:              qsTr("Active controller")
            labelText:          root._connected ? root._activeJoystick.name : ""
        }
    }

    //-------------------------------------------------------------------------
    //-- RC output enable
    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("RC Output")
        headingDescription: qsTr("When enabled and an aircraft is connected, the controller state is sent to the aircraft as RC channels (RC_CHANNELS_OVERRIDE, 25 Hz) — the aircraft sees it exactly like an RC receiver.")

        QGCCheckBox {
            id:         enableCheck
            enabled:    root._connected
            text:       qsTr("Enable RC override output")

            function _sync() {
                checked = root._activeVehicle ? root._activeVehicle.joystickEnabled
                                              : joystickManager.defaultJoystickEnabled
            }
            Component.onCompleted: _sync()
            onClicked: {
                // Record the operator's intent as the global default…
                joystickManager.defaultJoystickEnabled = checked
                // …and apply it live to the connected aircraft, if any.
                if (root._activeVehicle) {
                    root._activeVehicle.joystickEnabled = checked
                    root._activeVehicle.saveJoystickSettings()
                }
            }
            Connections {
                target: joystickManager
                function onDefaultJoystickEnabledChanged() { enableCheck._sync() }
            }
            Connections {
                target: QGroundControl.multiVehicleManager
                function onActiveVehicleChanged() { enableCheck._sync() }
            }
            Connections {
                target: root._activeVehicle
                ignoreUnknownSignals: true
                function onJoystickEnabledChanged() { enableCheck._sync() }
            }
        }

        QGCLabel {
            Layout.fillWidth:   true
            wrapMode:           Text.WordWrap
            font.pointSize:     ScreenTools.smallFontPointSize
            color:              qgcPal.text
            text:               root._activeVehicle
                                    ? qsTr("Applies to the connected aircraft now and is saved as the default for future connections.")
                                    : qsTr("No aircraft connected — saved as the default and applied automatically when an aircraft connects.")
        }
    }

    //-------------------------------------------------------------------------
    //-- Live output monitor (raw controls + remapped RC channels)
    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Live Output")
        headingDescription: qsTr("Raw controller values and the remapped RC channels. Move the controls to verify the connection.")
        visible:            root._connected

        property var _axisValues: [0, 0, 0, 0, 0]
        property bool _buttonDown: false
        // rcChannels only exists on the ACULA HID controller class
        property var _rcChannels: (root._connected && root._activeJoystick.rcChannels !== undefined)
                                      ? root._activeJoystick.rcChannels : []

        id: liveMonitor

        readonly property var _axisNames: [qsTr("X (roll)"), qsTr("Y (pitch)"), qsTr("Z"), qsTr("Rx"), qsTr("Knob")]

        Connections {
            target: root._activeJoystick
            ignoreUnknownSignals: true
            function onRawAxisValueChanged(index, value) {
                let vals = liveMonitor._axisValues.slice()
                if (index >= 0 && index < 5) {
                    vals[index] = value
                    liveMonitor._axisValues = vals
                }
            }
            function onRawButtonPressedChanged(index, pressed) {
                if (index === 0) {
                    liveMonitor._buttonDown = (pressed !== 0)
                }
            }
            function onRcChannelsChanged() {
                liveMonitor._rcChannels = root._activeJoystick.rcChannels
            }
        }

        Repeater {
            model: Math.min(root._connected ? root._activeJoystick.axisCount : 0, 5)

            RowLayout {
                Layout.fillWidth:   true
                spacing:            ScreenTools.defaultFontPixelWidth

                QGCLabel {
                    Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 12
                    text:                   liveMonitor._axisNames[index]
                    font.pointSize:         ScreenTools.smallFontPointSize
                }
                Rectangle {
                    Layout.fillWidth:   true
                    height:             ScreenTools.defaultFontPixelHeight * 0.8
                    radius:             2
                    color:              qgcPal.windowShadeDark
                    border.color:       qgcPal.text
                    border.width:       1
                    Rectangle {
                        // center-origin bar: value is ±32767
                        readonly property real frac: liveMonitor._axisValues[index] / 32767
                        x:      (frac >= 0) ? parent.width / 2 : parent.width / 2 * (1 + frac)
                        width:  Math.abs(frac) * parent.width / 2
                        height: parent.height - 4
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 2
                        color:  qgcPal.buttonHighlight
                    }
                    Rectangle {
                        anchors.horizontalCenter:   parent.horizontalCenter
                        width:                      1
                        height:                     parent.height
                        color:                      qgcPal.text
                        opacity:                    0.5
                    }
                }
                QGCLabel {
                    Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 7
                    horizontalAlignment:    Text.AlignRight
                    text:                   liveMonitor._axisValues[index]
                    font.pointSize:         ScreenTools.smallFontPointSize
                    font.family:            ScreenTools.fixedFontFamily
                }
            }
        }

        RowLayout {
            Layout.fillWidth:   true
            spacing:            ScreenTools.defaultFontPixelWidth

            QGCLabel {
                Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 12
                text:                   qsTr("Button")
                font.pointSize:         ScreenTools.smallFontPointSize
            }
            Rectangle {
                width:          ScreenTools.defaultFontPixelHeight * 0.8
                height:         width
                radius:         width / 2
                color:          liveMonitor._buttonDown ? qgcPal.buttonHighlight : qgcPal.windowShadeDark
                border.color:   qgcPal.text
                border.width:   1
            }
            QGCLabel {
                text:           liveMonitor._buttonDown ? qsTr("pressed") : qsTr("released")
                font.pointSize: ScreenTools.smallFontPointSize
            }
        }

        GridLayout {
            Layout.fillWidth:   true
            Layout.topMargin:   ScreenTools.defaultFontPixelHeight / 2
            columns:            12
            visible:            liveMonitor._rcChannels.length > 0

            Repeater {
                model: liveMonitor._rcChannels.length
                ColumnLayout {
                    spacing: 0
                    QGCLabel {
                        Layout.alignment:   Qt.AlignHCenter
                        text:               qsTr("ch%1").arg(index + 1)
                        font.pointSize:     ScreenTools.smallFontPointSize
                        color:              (index === 6) ? qgcPal.buttonHighlight : qgcPal.text  // ch7 = flight mode
                    }
                    QGCLabel {
                        Layout.alignment:   Qt.AlignHCenter
                        text:               (liveMonitor._rcChannels[index] > 0) ? liveMonitor._rcChannels[index] : "—"
                        font.pointSize:     ScreenTools.smallFontPointSize
                        font.family:        ScreenTools.fixedFontFamily
                    }
                }
            }
        }

        QGCLabel {
            Layout.fillWidth:   true
            wrapMode:           Text.WordWrap
            font.pointSize:     ScreenTools.smallFontPointSize
            color:              qgcPal.text
            visible:            liveMonitor._rcChannels.length > 0
            text:               qsTr("ch7 (highlighted) carries the flight-mode button. Channels shown as — are not driven.")
        }
    }
}
