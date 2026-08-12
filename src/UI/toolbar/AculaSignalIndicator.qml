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

// [ACULA] Datalink signal strength: signal icon + link quality percentage.
// Prefers RC RSSI, falls back to telemetry RSSI so something meaningful shows
// on any link. Replaces upstream's separate RC/telemetry RSSI indicators.
Item {
    id:             control
    width:          signalRow.width
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

    property bool showIndicator: true

    property var  _activeVehicle:   QGroundControl.multiVehicleManager.activeVehicle
    property bool _rcAvailable:     _activeVehicle && _activeVehicle.rcRSSI > 0 && _activeVehicle.rcRSSI <= 100
    property bool _telemAvailable:  _activeVehicle && _activeVehicle.telemetryLRSSI !== undefined && _activeVehicle.telemetryRRSSI !== 0
    property int  _percent:         _rcAvailable ? _activeVehicle.rcRSSI : (_telemAvailable ? _telemetryPercent : 0)
    // Telemetry RSSI is dBm (negative). Map -120..-50 dBm onto 0..100 %.
    property int  _telemetryPercent: {
        if (!_activeVehicle) return 0
        var dbm = _activeVehicle.telemetryLRSSI
        return Math.max(0, Math.min(100, Math.round((dbm + 120) * 100 / 70)))
    }
    property bool _haveSignal: _rcAvailable || _telemAvailable

    Row {
        id:             signalRow
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        spacing:        ScreenTools.defaultFontPixelWidth * 0.35

        QGCColoredImage {
            height:             parent.height * 0.7
            width:              height
            anchors.verticalCenter: parent.verticalCenter
            source:             "/res/acula/signal.png"
            color:                  qgcPal.buttonText
            fillMode:           Image.PreserveAspectFit
            mipmap:             true
            opacity:            _haveSignal ? 1 : 0.5
        }

        QGCLabel {
            // Fixed slot: value changes must not shift the icon or neighbours.
            width:                  ScreenTools.defaultFontPixelWidth * 5
            horizontalAlignment:    Text.AlignLeft
            anchors.verticalCenter: parent.verticalCenter
            color:                  qgcPal.buttonText
            text:                   _haveSignal ? _percent + "%" : qsTr("--")
        }
    }

    MouseArea {
        anchors.fill:   parent
        onClicked:      mainWindow.showIndicatorDrawer(signalInfoPage, control)
    }

    Component {
        id: signalInfoPage

        ToolIndicatorPage {
            showExpand: false

            contentComponent: SettingsGroupLayout {
                heading: qsTr("Link Signal")

                LabelledLabel {
                    label:      qsTr("RC RSSI")
                    labelText:  _rcAvailable ? _activeVehicle.rcRSSI + "%" : qsTr("N/A")
                }

                LabelledLabel {
                    label:      qsTr("Telemetry local")
                    labelText:  _telemAvailable ? _activeVehicle.telemetryLRSSI + " dBm" : qsTr("N/A")
                }

                LabelledLabel {
                    label:      qsTr("Telemetry remote")
                    labelText:  _telemAvailable ? _activeVehicle.telemetryRRSSI + " dBm" : qsTr("N/A")
                }
            }
        }
    }
}
