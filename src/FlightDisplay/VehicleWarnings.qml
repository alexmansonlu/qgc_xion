/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls

Rectangle {
    anchors.margins:    -ScreenTools.defaultFontPixelHeight
    height:             warningsCol.height
    width:              warningsCol.width
    color:              Qt.rgba(1, 1, 1, 0.5)
    radius:             ScreenTools.defaultFontPixelWidth / 2
    visible:            _noGPSLockVisible || _prearmErrorVisible || _noFlyZoneVisible

    property var  _activeVehicle:       QGroundControl.multiVehicleManager.activeVehicle
    property bool _noGPSLockVisible:    _activeVehicle && _activeVehicle.requiresGpsFix && !_activeVehicle.coordinate.isValid
    property bool _prearmErrorVisible:  _activeVehicle && !_activeVehicle.armed && _activeVehicle.prearmError && !_activeVehicle.healthAndArmingCheckReport.supported

    // [ACULA] No-fly zone (禁航區) breach warning
    property var  _noFlyManager:        QGroundControl.noFlyZoneManager
    property bool _noFlyZoneVisible:    _activeVehicle && _noFlyManager && _noFlyManager.vehicleInNoFlyZone

    Column {
        id:         warningsCol
        spacing:    ScreenTools.defaultFontPixelHeight

        QGCLabel {
            anchors.horizontalCenter:   parent.horizontalCenter
            visible:                    _noGPSLockVisible
            color:                      "black"
            font.pointSize:             ScreenTools.largeFontPointSize
            text:                       qsTr("No GPS Lock for Vehicle")
        }

        QGCLabel {
            anchors.horizontalCenter:   parent.horizontalCenter
            visible:                    _prearmErrorVisible
            color:                      "black"
            font.pointSize:             ScreenTools.largeFontPointSize
            text:                       _activeVehicle ? _activeVehicle.prearmError : ""
        }

        QGCLabel {
            anchors.horizontalCenter:   parent.horizontalCenter
            visible:                    _prearmErrorVisible
            width:                      ScreenTools.defaultFontPixelWidth * 50
            horizontalAlignment:        Text.AlignHCenter
            wrapMode:                   Text.WordWrap
            color:                      "black"
            font.pointSize:             ScreenTools.largeFontPointSize
            text:                       qsTr("The vehicle has failed a pre-arm check. In order to arm the vehicle, resolve the failure.")
        }

        // [ACULA] No-fly zone (禁航區) breach warning
        QGCLabel {
            anchors.horizontalCenter:   parent.horizontalCenter
            visible:                    _noFlyZoneVisible
            color:                      "#cc0000"
            font.bold:                  true
            font.pointSize:             ScreenTools.largeFontPointSize
            text:                       qsTr("⚠ 無人機已進入禁航區：%1").arg(_noFlyManager ? _noFlyManager.intrudedZoneName : "")
        }
    }
}
