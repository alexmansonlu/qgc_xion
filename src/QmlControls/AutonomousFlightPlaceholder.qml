import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import QGroundControl.Palette
import QGroundControl.ScreenTools

// [ACULA GCS] Feature E — Autonomous Flight placeholder UI.
// No functional logic. Displayed as a reserved screen for ACULA to expand.

Rectangle {
    color: qgcPal.window

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    ColumnLayout {
        anchors.horizontalCenter:   parent.horizontalCenter
        anchors.verticalCenter:     parent.verticalCenter
        anchors.verticalCenterOffset: -ScreenTools.defaultFontPixelHeight * 4
        spacing:                    ScreenTools.defaultFontPixelHeight * 2

        Image {
            Layout.alignment:   Qt.AlignHCenter
            source:             "/qmlimages/Waypoint.svg"
            width:              ScreenTools.defaultFontPixelHeight * 8
            height:             width
            fillMode:           Image.PreserveAspectFit
            opacity:            0.5
        }

        Text {
            Layout.alignment:   Qt.AlignHCenter
            text:               qsTr("Autonomous Flight")
            color:              qgcPal.text
            font.pixelSize:     ScreenTools.largeFontPixelSize
            font.bold:          true
        }

        Text {
            Layout.alignment:       Qt.AlignHCenter
            Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 40
            text:                   qsTr("This screen is reserved for autonomous flight features.\nFunctionality will be activated by ACULA.")
            color:                  qgcPal.text
            opacity:                0.6
            font.pixelSize:         ScreenTools.defaultFontPixelSize
            horizontalAlignment:    Text.AlignHCenter
            wrapMode:               Text.WordWrap
        }

        Rectangle {
            Layout.alignment:       Qt.AlignHCenter
            width:                  ScreenTools.defaultFontPixelWidth * 20
            height:                 ScreenTools.defaultFontPixelHeight * 2
            radius:                 height / 2
            color:                  qgcPal.primaryButton
            opacity:                0.4

            Text {
                anchors.centerIn:   parent
                text:               qsTr("Coming Soon")
                color:              qgcPal.primaryButtonText
                font.pixelSize:     ScreenTools.defaultFontPixelSize
            }
        }
    }
}
