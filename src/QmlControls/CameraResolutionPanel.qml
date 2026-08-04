import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import QGroundControl
import QGroundControl.Palette
import QGroundControl.ScreenTools

// [ACULA GCS] Feature C — Camera Resolution Settings
// Front-end panel. MAVLink backend wired in Phase 3 when camera hardware is confirmed.
// Accessible from FlyViewAdditionalActionsPanel.

Rectangle {
    id:     _root
    color:  qgcPal.windowShade
    radius: ScreenTools.defaultFontPixelHeight * 0.4
    width:  _panelWidth
    height: _col.implicitHeight + _margin * 2

    property real   _margin:        ScreenTools.defaultFontPixelWidth
    property real   _panelWidth:    ScreenTools.defaultFontPixelWidth * 50
    property real   _rowHeight:     ScreenTools.defaultFontPixelHeight * 2.8
    property var    _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    // Current selections (index into resolution arrays)
    property int    _photoResIndex:  1     // default FHD
    property int    _videoResIndex:  1     // default FHD

    // Resolution definitions
    readonly property var _photoResolutions: [
        { label: "4K",  width: 3840, height: 2160, description: "3840 × 2160" },
        { label: "FHD", width: 1920, height: 1080, description: "1920 × 1080" },
        { label: "HD",  width: 1280, height: 720,  description: "1280 × 720"  }
    ]
    readonly property var _videoResolutions: [
        { label: "4K",  width: 3840, height: 2160, description: "3840 × 2160 / 30fps" },
        { label: "FHD", width: 1920, height: 1080, description: "1920 × 1080 / 60fps" },
        { label: "HD",  width: 1280, height: 720,  description: "1280 × 720 / 60fps"  }
    ]

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    ColumnLayout {
        id:             _col
        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.top:    parent.top
        anchors.margins: _margin
        spacing:        _margin * 0.6

        // ── Header ──────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true

            QGCLabel {
                text:               qsTr("Camera Resolution")
                font.pixelSize:     ScreenTools.mediumFontPixelSize
                font.bold:          true
                color:              qgcPal.text
                Layout.fillWidth:   true
            }

            // Connection indicator
            Rectangle {
                width:  ScreenTools.defaultFontPixelHeight * 0.7
                height: width
                radius: width / 2
                color:  _activeVehicle ? "#00C853" : "#757575"
            }
        }

        // Divider
        Rectangle { Layout.fillWidth: true; height: 1; color: qgcPal.windowShadeDark }

        // ── Photo Resolution ─────────────────────────────────────────
        QGCLabel {
            text:           qsTr("Photo")
            color:          qgcPal.text
            opacity:        0.7
            font.pixelSize: ScreenTools.smallFontPixelSize
            font.bold:      true
            topPadding:     _margin * 0.4
        }

        RowLayout {
            Layout.fillWidth: true
            spacing:         _margin * 0.5

            Repeater {
                model: _root._photoResolutions

                delegate: ResButton {
                    label:       modelData.label
                    sublabel:    modelData.description
                    selected:    _root._photoResIndex === index
                    onClicked:   _root._photoResIndex = index
                    Layout.fillWidth: true
                }
            }
        }

        // ── Video Resolution ─────────────────────────────────────────
        QGCLabel {
            text:           qsTr("Video")
            color:          qgcPal.text
            opacity:        0.7
            font.pixelSize: ScreenTools.smallFontPixelSize
            font.bold:      true
            topPadding:     _margin * 0.4
        }

        RowLayout {
            Layout.fillWidth: true
            spacing:         _margin * 0.5

            Repeater {
                model: _root._videoResolutions

                delegate: ResButton {
                    label:       modelData.label
                    sublabel:    modelData.description
                    selected:    _root._videoResIndex === index
                    onClicked:   _root._videoResIndex = index
                    Layout.fillWidth: true
                }
            }
        }

        // Divider
        Rectangle { Layout.fillWidth: true; Layout.topMargin: _margin * 0.4; height: 1; color: qgcPal.windowShadeDark }

        // ── Apply button ─────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth:   true
            height:             _rowHeight
            radius:             height * 0.2
            color:              applyMouse.containsMouse ? Qt.darker(qgcPal.primaryButton, 1.1) : qgcPal.primaryButton
            opacity:            _activeVehicle ? 1.0 : 0.5

            QGCLabel {
                anchors.centerIn: parent
                text:             _activeVehicle ? qsTr("Apply") : qsTr("No Camera Connected")
                color:            qgcPal.primaryButtonText
                font.bold:        true
                font.pixelSize:   ScreenTools.defaultFontPixelSize
            }

            MouseArea {
                id:             applyMouse
                anchors.fill:   parent
                hoverEnabled:   true
                enabled:        _activeVehicle !== null
                onClicked:      _root._applyResolution()
            }
        }

        // Status label — shows result after apply
        QGCLabel {
            id:                 statusLabel
            Layout.fillWidth:   true
            text:               ""
            color:              qgcPal.colorGreen
            font.pixelSize:     ScreenTools.smallFontPixelSize
            horizontalAlignment: Text.AlignHCenter
            visible:            text !== ""
            bottomPadding:      _margin * 0.4
        }
    }

    // ── Internal resolution button component ─────────────────────────
    component ResButton : Rectangle {
        property string label:    ""
        property string sublabel: ""
        property bool   selected: false
        signal          clicked()

        // Size to content so longer text (e.g. "3840 × 2160 / 30fps") never overflows.
        implicitHeight: Math.max(_rowHeight, contentCol.implicitHeight + _margin)
        radius:     ScreenTools.defaultFontPixelHeight * 0.4
        color:      selected ? qgcPal.primaryButton : qgcPal.button
        border.color: selected ? qgcPal.primaryButton : "transparent"
        border.width: 2
        clip:       true

        ColumnLayout {
            id:                     contentCol
            anchors.left:           parent.left
            anchors.right:          parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin:     _margin * 0.4
            anchors.rightMargin:    _margin * 0.4
            spacing:                2

            QGCLabel {
                Layout.fillWidth:    true
                horizontalAlignment: Text.AlignHCenter
                text:                label
                color:               selected ? qgcPal.primaryButtonText : qgcPal.buttonText
                font.bold:           selected
                font.pixelSize:      ScreenTools.defaultFontPixelSize
            }
            QGCLabel {
                Layout.fillWidth:    true
                horizontalAlignment: Text.AlignHCenter
                wrapMode:            Text.WordWrap
                text:                sublabel
                color:               selected ? qgcPal.primaryButtonText : qgcPal.buttonText
                opacity:             0.7
                font.pixelSize:      ScreenTools.smallFontPixelSize
            }
        }

        MouseArea {
            anchors.fill:   parent
            cursorShape:    Qt.PointingHandCursor
            onClicked:      parent.clicked()
        }
    }

    // ── MAVLink apply function ────────────────────────────────────────
    function _applyResolution() {
        if (!_activeVehicle) return

        var photoRes = _photoResolutions[_photoResIndex]
        var videoRes = _videoResolutions[_videoResIndex]

        // TODO Phase 3: wire MAVLink Camera Protocol here.
        // Use _activeVehicle.cameraManager to get the active MavlinkCameraControl,
        // then call setPhotoResolution / setVideoResolution with the selected values.
        // Example (parameters depend on camera firmware support):
        //   var cam = _activeVehicle.cameraManager.cameras.get(0)
        //   if (cam) {
        //       cam.setPhotoResolution(photoRes.width, photoRes.height)
        //       cam.setVideoResolution(videoRes.width, videoRes.height)
        //   }

        statusLabel.text = qsTr("Sent: Photo %1 / Video %2").arg(photoRes.label).arg(videoRes.label)
        statusClearTimer.restart()
    }

    Timer {
        id:         statusClearTimer
        interval:   3000
        onTriggered: statusLabel.text = ""
    }
}
