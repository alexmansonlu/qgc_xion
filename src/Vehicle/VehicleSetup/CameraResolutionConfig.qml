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

// [ACULA GCS] Feature C — Camera resolution setup page (Vehicle Setup → Camera).
//
// Hosts the photo/video resolution frontend (CameraResolutionPanel). Replaces the
// default autopilot "Camera" setup component, which is hidden in SetupView.
//
// NOTE: resolution is set over MAVLink via the camera's resolution PARAMETER
// (PARAM_EXT_SET on e.g. CAM_VIDRES / CAM_PHOTORES), not a dedicated command —
// the available options come from the camera's definition file. The backend is
// wired once ACULA's camera definition is confirmed.

Item {
    id: root

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    QGCFlickable {
        anchors.fill:       parent
        anchors.margins:    ScreenTools.defaultFontPixelWidth
        contentHeight:      col.height
        clip:               true

        ColumnLayout {
            id:         col
            width:      parent.width
            spacing:    ScreenTools.defaultFontPixelHeight

            QGCLabel {
                text:           qsTr("Camera Resolution")
                font.pointSize: ScreenTools.largeFontPointSize
                Layout.topMargin: ScreenTools.defaultFontPixelHeight / 2
            }

            QGCLabel {
                Layout.fillWidth:   true
                wrapMode:           Text.WordWrap
                color:              qgcPal.text
                text:               qsTr("Set the photo and video resolution. The available options and the final values are provided by the connected camera.")
            }

            CameraResolutionPanel {
                Layout.alignment:   Qt.AlignLeft
                Layout.topMargin:   ScreenTools.defaultFontPixelHeight / 2
            }
        }
    }
}
