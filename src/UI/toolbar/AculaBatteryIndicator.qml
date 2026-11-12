/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.MultiVehicleManager
import QGroundControl.ScreenTools
import QGroundControl.Palette

// [ACULA] Two-row battery readout: aircraft on top, handheld controller below,
// each as "xx%(yy.yV)".
//
// The controller row is live data: the STM32 reads the BQ2085 gas gauge and
// reports battery % + voltage in its HID report (v2, 8-byte format); the
// values surface here via JoystickUsbHid's batteryValid/Percent/Voltage
// properties. Shows "--" until a battery-capable controller is connected.
Item {
    id:             control
    width:          batteryRow.width
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

    property bool showIndicator: true

    property var  _activeVehicle:   QGroundControl.multiVehicleManager.activeVehicle
    property var  _battery:         (_activeVehicle && _activeVehicle.batteries.count > 0) ? _activeVehicle.batteries.get(0) : null
    property bool _droneValid:      _battery && !isNaN(_battery.percentRemaining.rawValue) && !isNaN(_battery.voltage.rawValue)

    // --- controller battery (from the STM32 HID report via JoystickUsbHid) --
    // batteryValid only exists on the USB-HID backend — guard with typeof so
    // desktop/SDL joysticks (no battery properties) read as "no data".
    property var  _ctrlJoystick:    joystickManager.activeJoystick
    property bool _ctrlValid:       _ctrlJoystick && (typeof _ctrlJoystick.batteryValid === "boolean") && _ctrlJoystick.batteryValid
    property real _ctrlPercent:     _ctrlValid ? _ctrlJoystick.batteryPercent : 0
    property real _ctrlVoltage:     _ctrlValid ? _ctrlJoystick.batteryVoltage : 0
    // -----------------------------------------------------------------------

    function fmt(percent, voltage) {
        return Math.round(percent) + "%(" + voltage.toFixed(1) + "V)"
    }

    function levelColor(percent) {
        if (percent <= 20) return qgcPal.colorRed
        if (percent <= 40) return qgcPal.colorOrange
        return qgcPal.buttonText
    }

    // Fixed geometry so a changing percentage or voltage never moves the icons
    // or the indicators next to this one. "100%(14.7V)" is the widest string.
    property real _iconSize:    ScreenTools.defaultFontPixelHeight
    property real _valueWidth:  ScreenTools.defaultFontPixelWidth * 12
    property real _rowSpacing:  ScreenTools.defaultFontPixelHeight * 0.25

    Row {
        id:             batteryRow
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        spacing:        ScreenTools.defaultFontPixelWidth * 0.35

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing:                _rowSpacing

            QGCColoredImage {
                height:     _iconSize
                width:      height
                source:     "/res/acula/uav.png"
                color:      qgcPal.buttonText
                fillMode:   Image.PreserveAspectFit
                mipmap:     true
                opacity:    _droneValid ? 1 : 0.5
            }

            QGCColoredImage {
                height:     _iconSize
                width:      height
                source:     "/res/acula/joystick.png"
                color:      qgcPal.buttonText
                fillMode:   Image.PreserveAspectFit
                mipmap:     true
                opacity:    _ctrlValid ? 1 : 0.5
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing:                _rowSpacing

            QGCLabel {
                width:                  _valueWidth
                height:                 _iconSize
                verticalAlignment:      Text.AlignVCenter
                horizontalAlignment:    Text.AlignLeft
                text:                   _droneValid ? fmt(_battery.percentRemaining.rawValue, _battery.voltage.rawValue) : qsTr("--")
                color:                  _droneValid ? levelColor(_battery.percentRemaining.rawValue) : qgcPal.buttonText
            }

            QGCLabel {
                width:                  _valueWidth
                height:                 _iconSize
                verticalAlignment:      Text.AlignVCenter
                horizontalAlignment:    Text.AlignLeft
                text:                   _ctrlValid ? fmt(_ctrlPercent, _ctrlVoltage) : qsTr("--")
                color:                  _ctrlValid ? levelColor(_ctrlPercent) : qgcPal.buttonText
            }
        }
    }

    MouseArea {
        anchors.fill:   parent
        onClicked:      mainWindow.showIndicatorDrawer(batteryInfoPage, control)
    }

    Component {
        id: batteryInfoPage

        ToolIndicatorPage {
            showExpand: false

            contentComponent: SettingsGroupLayout {
                heading: qsTr("Battery")

                LabelledLabel {
                    label:      qsTr("Aircraft")
                    labelText:  _droneValid ? fmt(_battery.percentRemaining.rawValue, _battery.voltage.rawValue) : qsTr("N/A")
                }

                LabelledLabel {
                    label:      qsTr("Aircraft current")
                    labelText:  (_battery && !isNaN(_battery.current.rawValue)) ? _battery.current.valueString + " " + _battery.current.units : qsTr("N/A")
                }

                LabelledLabel {
                    label:      qsTr("Controller")
                    labelText:  _ctrlValid ? fmt(_ctrlPercent, _ctrlVoltage) : qsTr("N/A")
                }
            }
        }
    }
}
