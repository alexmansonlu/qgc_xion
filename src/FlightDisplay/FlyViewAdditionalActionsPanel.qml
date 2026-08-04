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
import QGroundControl.ScreenTools
import QGroundControl.Palette

ColumnLayout {
    property var additionalActions
    property var mavlinkActions
    property var customActions

    property var  _activeVehicle:    QGroundControl.multiVehicleManager.activeVehicle
    property var  _guidedController: globals.guidedControllerFlyView

    spacing: ScreenTools.defaultFontPixelHeight * 0.3

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    // ── Pre-defined Additional Guided Actions ────────────────────────
    Repeater {
        model: additionalActions.model

        QGCButton {
            Layout.fillWidth:   true
            text:               modelData.title
            visible:            modelData.visible

            onClicked: {
                dropPanel.hide()
                _guidedController.confirmAction(modelData.action)
            }
        }
    }

    // ── Custom Build Actions ─────────────────────────────────────────
    Repeater {
        model: customActions.model

        QGCButton {
            Layout.fillWidth:   true
            text:               modelData.title
            visible:            modelData.visible

            onClicked: {
                dropPanel.hide()
                _guidedController.confirmAction(modelData.action)
            }
        }
    }

    // [ACULA GCS] Feature C — Camera Resolution moved to Vehicle Setup → Camera
    // (CameraResolutionConfig.qml). No longer shown as a fly-view overlay.

    // ── User-defined MAVLink Actions ─────────────────────────────────
    Repeater {
        model: _activeVehicle ? mavlinkActions : undefined

        QGCButton {
            Layout.fillWidth:   true
            text:               object.label

            onClicked: {
                dropPanel.hide()
                object.sendTo(_activeVehicle)
            }
        }
    }
}
