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

// [ACULA] Flight telemetry block for the toolbar: three columns of two rows each,
// replacing the bottom-right telemetry bar that upstream shows over the map.
//
//   相對高度 / 上升速度      home點距離 / 總航程      飛行速度 / 飛行時間
Item {
    id:             control
    width:          telemetryRow.width
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

    property bool showIndicator: true

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    function factText(fact, decimals) {
        if (!_activeVehicle || !fact || isNaN(fact.rawValue)) {
            return qsTr("--")
        }
        return fact.rawValue.toFixed(decimals === undefined ? 1 : decimals) + " " + fact.units
    }

    // flightTime is seconds; show as m:ss so it stays narrow in the toolbar.
    function flightTimeText() {
        // flightTime itself is undefined until a vehicle is connected.
        if (!_activeVehicle || !_activeVehicle.flightTime || isNaN(_activeVehicle.flightTime.rawValue)) {
            return qsTr("--")
        }
        var total = Math.floor(_activeVehicle.flightTime.rawValue)
        var minutes = Math.floor(total / 60)
        var seconds = total % 60
        return minutes + ":" + (seconds < 10 ? "0" : "") + seconds
    }

    Row {
        id:             telemetryRow
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        spacing:        ScreenTools.defaultFontPixelWidth * 4   // generous gap between the three columns

        // ---- 相對高度 / 上升速度 ----
        AculaTelemetryColumn {
            anchors.verticalCenter: parent.verticalCenter
            topIcon:                "/res/acula/uav.png"
            topText:                factText(_activeVehicle ? _activeVehicle.altitudeRelative : null)
            bottomIcon:             "/res/acula/route.png"
            bottomText:             factText(_activeVehicle ? _activeVehicle.climbRate : null)
        }

        // ---- home點距離 / 總航程 ----
        AculaTelemetryColumn {
            anchors.verticalCenter: parent.verticalCenter
            topIcon:                "/res/acula/gps.png"
            topText:                factText(_activeVehicle ? _activeVehicle.distanceToHome : null)
            bottomIcon:             "/res/acula/route.png"
            bottomText:             factText(_activeVehicle ? _activeVehicle.flightDistance : null)
        }

        // ---- 飛行速度 / 飛行時間 ----
        AculaTelemetryColumn {
            anchors.verticalCenter: parent.verticalCenter
            topIcon:                "/res/acula/man-walking.png"
            topText:                factText(_activeVehicle ? _activeVehicle.groundSpeed : null)
            bottomIcon:             "/res/acula/clock.png"
            bottomText:             flightTimeText()
        }
    }

    MouseArea {
        anchors.fill:   parent
        onClicked:      mainWindow.showIndicatorDrawer(telemetryInfoPage, control)
    }

    Component {
        id: telemetryInfoPage

        ToolIndicatorPage {
            showExpand: false

            contentComponent: SettingsGroupLayout {
                heading: qsTr("Flight Telemetry")

                LabelledLabel {
                    label:      qsTr("相對高度 Relative altitude")
                    labelText:  factText(_activeVehicle ? _activeVehicle.altitudeRelative : null)
                }

                LabelledLabel {
                    label:      qsTr("上升速度 Climb rate")
                    labelText:  factText(_activeVehicle ? _activeVehicle.climbRate : null)
                }

                LabelledLabel {
                    label:      qsTr("home點距離 Distance to home")
                    labelText:  factText(_activeVehicle ? _activeVehicle.distanceToHome : null)
                }

                LabelledLabel {
                    label:      qsTr("總航程 Flight distance")
                    labelText:  factText(_activeVehicle ? _activeVehicle.flightDistance : null)
                }

                LabelledLabel {
                    label:      qsTr("飛行速度 Ground speed")
                    labelText:  factText(_activeVehicle ? _activeVehicle.groundSpeed : null)
                }

                LabelledLabel {
                    label:      qsTr("飛行時間 Flight time")
                    labelText:  flightTimeText()
                }
            }
        }
    }
}
