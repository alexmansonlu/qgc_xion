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

// [ACULA] Vehicle temperature (autopilot IMU sensor) with thermometer icon.
Item {
    id:             control
    width:          tempRow.width
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

    property bool showIndicator: true

    property var  _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property var  _tempFact:      _activeVehicle ? _activeVehicle.imuTemp : null
    property bool _tempValid:     _tempFact && !isNaN(_tempFact.rawValue)

    Row {
        id:             tempRow
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        spacing:        ScreenTools.defaultFontPixelWidth * 0.35

        QGCColoredImage {
            height:                 parent.height * 0.7
            width:                  height
            anchors.verticalCenter: parent.verticalCenter
            source:                 "/res/acula/thermometer.png"
            color:                  qgcPal.buttonText
            fillMode:               Image.PreserveAspectFit
            mipmap:                 true
            opacity:                _tempValid ? 1 : 0.5
        }

        QGCLabel {
            // Fixed slot: value changes must not shift the icon or neighbours.
            width:                  ScreenTools.defaultFontPixelWidth * 5
            horizontalAlignment:    Text.AlignLeft
            anchors.verticalCenter: parent.verticalCenter
            color:                  qgcPal.buttonText
            text:                   _tempValid ? _tempFact.rawValue.toFixed(0) + "°C" : qsTr("--")
        }
    }

    MouseArea {
        anchors.fill:   parent
        onClicked:      mainWindow.showIndicatorDrawer(temperatureInfoPage, control)
    }

    Component {
        id: temperatureInfoPage

        ToolIndicatorPage {
            showExpand: false

            contentComponent: SettingsGroupLayout {
                heading: qsTr("Temperature")

                LabelledLabel {
                    label:      qsTr("Autopilot IMU")
                    labelText:  _tempValid ? _tempFact.valueString + " " + _tempFact.units : qsTr("N/A")
                }
            }
        }
    }
}
