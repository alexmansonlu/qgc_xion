/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick

import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.Palette

// [ACULA] One toolbar telemetry column: two icon+value rows stacked vertically.
//
// Geometry is fixed, not content-driven: the icon column and the value column
// both have constant widths, so a changing value never shifts the icon or the
// neighbouring columns. Values are right-aligned in their slot so the digits
// line up between the two rows.
Column {
    id: root

    spacing: rowSpacing

    property string topIcon
    property string topText
    property string bottomIcon
    property string bottomText

    property real iconSize:     ScreenTools.defaultFontPixelHeight
    property real valueWidth:   ScreenTools.defaultFontPixelWidth * 9
    property real iconSpacing:  ScreenTools.defaultFontPixelWidth * 0.35
    property real rowSpacing:   ScreenTools.defaultFontPixelHeight * 0.25

    Repeater {
        model: [
            { icon: root.topIcon,    value: root.topText },
            { icon: root.bottomIcon, value: root.bottomText }
        ]

        Row {
            spacing: root.iconSpacing

            QGCColoredImage {
                width:                  root.iconSize
                height:                 root.iconSize
                anchors.verticalCenter: parent.verticalCenter
                source:                 modelData.icon
                color:                  qgcPal.buttonText
                fillMode:               Image.PreserveAspectFit
                mipmap:                 true
            }

            QGCLabel {
                // Left-aligned inside a fixed-width slot: the number sits right
                // next to its icon, while the constant width keeps the layout
                // from shifting as values change.
                width:                  root.valueWidth
                horizontalAlignment:    Text.AlignLeft
                elide:                  Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
                color:                  qgcPal.buttonText
                text:                   modelData.value
            }
        }
    }
}
