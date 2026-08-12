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
// The controller row is a PLACEHOLDER until the BQ24810/BQ2085 battery board is
// read over USB (deliverable 1/2). Wire it up by pointing `_ctrlPercent` and
// `_ctrlVoltage` at the real source; the layout does not need to change.
Item {
    id:             control
    width:          batteryRow.width
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

    property bool showIndicator: true

    property var  _activeVehicle:   QGroundControl.multiVehicleManager.activeVehicle
    property var  _battery:         (_activeVehicle && _activeVehicle.batteries.count > 0) ? _activeVehicle.batteries.get(0) : null
    property bool _droneValid:      _battery && !isNaN(_battery.percentRemaining.rawValue) && !isNaN(_battery.voltage.rawValue)

    // --- placeholder controller battery ------------------------------------
    property bool _ctrlValid:       true
    property real _ctrlPercent:     87
    property real _ctrlVoltage:     8.1
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
                    label:      qsTr("Controller (placeholder)")
                    labelText:  fmt(_ctrlPercent, _ctrlVoltage)
                }
            }
        }
    }
}
