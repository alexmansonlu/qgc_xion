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
    property bool _cameraExpanded:   false

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

    // ── [ACULA GCS] Feature C — Camera Resolution ────────────────────
    Rectangle {
        Layout.fillWidth:   true
        height:             ScreenTools.defaultFontPixelHeight * 2.5
        radius:             height * 0.2
        color:              _cameraExpanded ? qgcPal.primaryButton : qgcPal.button

        RowLayout {
            anchors.fill:           parent
            anchors.leftMargin:     ScreenTools.defaultFontPixelWidth
            anchors.rightMargin:    ScreenTools.defaultFontPixelWidth

            QGCColoredImage {
                width:              ScreenTools.defaultFontPixelHeight * 1.2
                height:             width
                source:             "/res/AculaIconDrone.png"
                color:              _cameraExpanded ? qgcPal.primaryButtonText : qgcPal.buttonText
                fillMode:           Image.PreserveAspectFit
            }

            QGCLabel {
                Layout.fillWidth:   true
                text:               qsTr("Camera Resolution")
                color:              _cameraExpanded ? qgcPal.primaryButtonText : qgcPal.buttonText
                font.pixelSize:     ScreenTools.defaultFontPixelSize
            }

            QGCLabel {
                text:   _cameraExpanded ? "▲" : "▼"
                color:  _cameraExpanded ? qgcPal.primaryButtonText : qgcPal.buttonText
                font.pixelSize: ScreenTools.smallFontPixelSize
            }
        }

        MouseArea {
            anchors.fill:   parent
            cursorShape:    Qt.PointingHandCursor
            onClicked:      _cameraExpanded = !_cameraExpanded
        }
    }

    Loader {
        Layout.fillWidth:   true
        active:             _cameraExpanded
        sourceComponent:    Component {
            CameraResolutionPanel {}
        }
    }

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
