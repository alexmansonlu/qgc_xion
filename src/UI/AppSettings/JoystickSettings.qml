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
import QGroundControl.Controllers
import QGroundControl.ScreenTools
import QGroundControl.Palette

// [ACULA GCS] Consolidated controller / 搖桿 setup page.
//
// All joystick configuration lives here in Application Settings, independent of
// whether an aircraft is connected (the handheld controller is always attached
// to the RB3). Contains: connection status + warning, enable toggle, 飛手模式
// (US/Japan stick mode), and the embedded calibration wizard.
//
// The HID->RC translation happens inside QGC's joystick subsystem, which reads
// the gamepad and sends MANUAL_CONTROL. No MCU reconfiguration, no FC params.
//
//   Mode 2 (American):  L-vert = Throttle, R-vert = Pitch
//   Mode 1 (Japanese):  L-vert = Pitch,    R-vert = Throttle
//
// Strings are English source + zh_TW translations (qgc_source_zh_TW.ts,
// context "JoystickSettings") so the page follows the app language setting.

SettingsPage {
    id: root

    property var  _activeJoystick: joystickManager.activeJoystick
    property var  _activeVehicle:  QGroundControl.multiVehicleManager.activeVehicle
    property bool _connected:      _activeJoystick !== null
    property bool _calibrated:     _connected && _activeJoystick.calibrated
    property bool _buttonsOnly:    _connected && _activeJoystick.axisCount === 0

    readonly property int _modeJapan:    1
    readonly property int _modeAmerican: 2

    QGCPalette { id: qgcPal }

    // Calibration controller — used by the embedded JoystickConfigCalibration.qml
    // (resolved through this document's context) and for the live stick-mode state.
    JoystickConfigController { id: controller }

    Component.onCompleted: if (_connected) controller.start()

    Connections {
        target: joystickManager
        function onActiveJoystickChanged() { if (root._connected) controller.start() }
    }

    //-------------------------------------------------------------------------
    //-- Connection status
    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Controller")

        QGCLabel {
            Layout.fillWidth:   true
            wrapMode:           Text.WordWrap
            color:              qgcPal.warningText
            visible:            !root._connected
            text:               qsTr("No controller detected — connect the handheld controller over USB.")
        }

        LabelledLabel {
            Layout.fillWidth:   true
            visible:            root._connected
            label:              qsTr("Active controller")
            labelText:          root._connected ? root._activeJoystick.name : ""
        }
    }

    //-------------------------------------------------------------------------
    //-- Enable joystick input
    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Joystick Input")

        QGCCheckBox {
            id:         enableCheck
            enabled:    root._calibrated
            text:       root._calibrated ? qsTr("Enable joystick input")
                                         : qsTr("Enable not allowed (calibrate first)")

            function _sync() {
                checked = root._activeVehicle ? root._activeVehicle.joystickEnabled
                                              : joystickManager.defaultJoystickEnabled
            }
            Component.onCompleted: _sync()
            onClicked: {
                // Always record the operator's intent as the global default…
                joystickManager.defaultJoystickEnabled = checked
                // …and apply it live to the connected aircraft, if any.
                if (root._activeVehicle) {
                    root._activeVehicle.joystickEnabled = checked
                    root._activeVehicle.saveJoystickSettings()
                }
            }
            Connections {
                target: joystickManager
                function onDefaultJoystickEnabledChanged() { enableCheck._sync() }
            }
            Connections {
                target: QGroundControl.multiVehicleManager
                function onActiveVehicleChanged() { enableCheck._sync() }
            }
            Connections {
                target: root._activeVehicle
                ignoreUnknownSignals: true
                function onJoystickEnabledChanged() { enableCheck._sync() }
            }
        }

        QGCLabel {
            Layout.fillWidth:   true
            wrapMode:           Text.WordWrap
            font.pointSize:     ScreenTools.smallFontPointSize
            color:              qgcPal.text
            text:               root._activeVehicle
                                    ? qsTr("Applies to the connected aircraft now and is saved as the default for future connections.")
                                    : qsTr("No aircraft connected — this is saved as the default and applied automatically when an aircraft connects.")
        }
    }

    //-------------------------------------------------------------------------
    //-- 飛手模式 (Pilot stick mode)
    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Pilot Stick Mode")
        headingDescription: qsTr("Choose how the two sticks map to throttle and pitch. Yaw and roll are the same in both modes.")
        visible:            !root._buttonsOnly

        RowLayout {
            Layout.fillWidth:   true
            Layout.topMargin:   ScreenTools.defaultFontPixelHeight / 2
            spacing:            ScreenTools.defaultFontPixelWidth * 2

            ModeCard {
                Layout.fillWidth:   true
                title:              qsTr("Mode 2")
                subtitle:           qsTr("American")
                leftLabel:          qsTr("Throttle")
                rightLabel:         qsTr("Pitch")
                selected:           controller.transmitterMode === root._modeAmerican
                enabled:            root._connected && !controller.calibrating
                onClicked:          controller.transmitterMode = root._modeAmerican
            }

            ModeCard {
                Layout.fillWidth:   true
                title:              qsTr("Mode 1")
                subtitle:           qsTr("Japanese")
                leftLabel:          qsTr("Pitch")
                rightLabel:         qsTr("Throttle")
                selected:           controller.transmitterMode === root._modeJapan
                enabled:            root._connected && !controller.calibrating
                onClicked:          controller.transmitterMode = root._modeJapan
            }
        }

        QGCLabel {
            Layout.fillWidth:   true
            Layout.topMargin:   ScreenTools.defaultFontPixelHeight / 2
            wrapMode:           Text.WordWrap
            font.pointSize:     ScreenTools.smallFontPointSize
            color:              qgcPal.text
            text:               qsTr("The horizontal stick directions (yaw / roll) are identical in both modes; only the vertical directions (throttle / pitch) swap.")
        }
    }

    //-------------------------------------------------------------------------
    //-- Calibration (embedded wizard)
    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Calibration")
        headingDescription: qsTr("Move both sticks to their extremes when prompted. Calibration is required before the joystick can be enabled.")
        visible:            root._connected && !root._buttonsOnly

        Loader {
            Layout.fillWidth:   true
            Layout.alignment:   Qt.AlignHCenter
            // controller + _activeJoystick are resolved from this document's context
            active:             root._connected && !root._buttonsOnly
            source:             "qrc:/qml/QGroundControl/VehicleSetup/JoystickConfigCalibration.qml"
        }
    }

    //-------------------------------------------------------------------------
    //-- Reusable: selectable stick-mode card
    component ModeCard: Rectangle {
        id:             card
        implicitHeight: cardCol.implicitHeight + ScreenTools.defaultFontPixelHeight * 1.5
        radius:         ScreenTools.defaultFontPixelWidth / 2
        color:          selected ? qgcPal.buttonHighlight : qgcPal.windowShadeDark
        border.color:   selected ? qgcPal.buttonHighlight : qgcPal.text
        border.width:   selected ? 2 : 1
        opacity:        enabled ? 1.0 : 0.4

        property string title
        property string subtitle
        property string leftLabel
        property string rightLabel
        property bool   selected
        signal clicked()

        ColumnLayout {
            id:                 cardCol
            anchors.centerIn:   parent
            width:              parent.width - ScreenTools.defaultFontPixelWidth * 2
            spacing:            ScreenTools.defaultFontPixelHeight / 3

            QGCLabel {
                Layout.alignment:   Qt.AlignHCenter
                text:               card.title
                font.pointSize:     ScreenTools.mediumFontPointSize
                font.bold:          true
                color:              card.selected ? qgcPal.buttonHighlightText : qgcPal.text
            }
            QGCLabel {
                Layout.alignment:   Qt.AlignHCenter
                text:               card.subtitle
                font.pointSize:     ScreenTools.smallFontPointSize
                color:              card.selected ? qgcPal.buttonHighlightText : qgcPal.text
            }

            RowLayout {
                Layout.alignment:   Qt.AlignHCenter
                Layout.topMargin:   ScreenTools.defaultFontPixelHeight / 2
                spacing:            ScreenTools.defaultFontPixelWidth * 3

                StickGlyph { vertLabel: card.leftLabel;  horizLabel: qsTr("Yaw");  highlight: card.selected }
                StickGlyph { vertLabel: card.rightLabel; horizLabel: qsTr("Roll"); highlight: card.selected }
            }
        }

        MouseArea {
            anchors.fill:   parent
            enabled:        card.enabled
            onClicked:      card.clicked()
        }
    }

    //-- Reusable: single stick glyph (vertical label above, horizontal below)
    component StickGlyph: ColumnLayout {
        property string vertLabel
        property string horizLabel
        property bool   highlight

        readonly property color _fg: highlight ? qgcPal.buttonHighlightText : qgcPal.text

        QGCLabel {
            Layout.alignment:    Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            text:                vertLabel
            font.pointSize:      ScreenTools.smallFontPointSize
            color:               _fg
        }
        Rectangle {
            Layout.alignment:   Qt.AlignHCenter
            width:              ScreenTools.defaultFontPixelWidth * 6
            height:             width
            radius:             width / 2
            color:              "transparent"
            border.color:       _fg
            border.width:       1
            Rectangle {
                anchors.centerIn:   parent
                width:              parent.width / 2.5
                height:             width
                radius:             width / 2
                color:              _fg
            }
        }
        QGCLabel {
            Layout.alignment:    Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            text:                horizLabel
            font.pointSize:      ScreenTools.smallFontPointSize
            color:               _fg
        }
    }
}
