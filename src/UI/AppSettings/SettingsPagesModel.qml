/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQml.Models

import QGroundControl
import QGroundControl.ScreenTools

// [ACULA GCS] Trimmed settings pages — only pages relevant to client spec.
// Hidden: Plan View, Video (GStreamer OFF), ADSB Server, Remote ID, Help, PX4 Log.

ListModel {
    ListElement {
        name: qsTr("General")
        url: "qrc:/qml/QGroundControl/AppSettings/GeneralSettings.qml"
        iconUrl: "qrc:/res/AculaIconSetting.png"
        pageVisible: function() { return true }
    }

    ListElement {
        name: qsTr("Fly View")
        url: "qrc:/qml/QGroundControl/AppSettings/FlyViewSettings.qml"
        iconUrl: "qrc:/qmlimages/PaperPlane.svg"
        pageVisible: function() { return true }
    }

    // [ACULA] Plan View hidden — Plan view removed from navigation
    // ListElement { name: qsTr("Plan View") ... }

    // [ACULA] Video hidden — GStreamer disabled in this build (re-enable Phase 3)
    // ListElement { name: qsTr("Video") ... }

    ListElement {
        name: qsTr("Telemetry")
        url: "qrc:/qml/QGroundControl/AppSettings/TelemetrySettings.qml"
        iconUrl: "qrc:/InstrumentValueIcons/drone.svg"
        pageVisible: function() { return true }
    }

    // [ACULA] ADSB Server hidden — not in client spec
    // ListElement { name: qsTr("ADSB Server") ... }

    ListElement {
        name: qsTr("Comm Links")
        url: "qrc:/qml/QGroundControl/AppSettings/LinkSettings.qml"
        iconUrl: "qrc:/InstrumentValueIcons/usb.svg"
        pageVisible: function() { return true }
    }

    ListElement {
        name: qsTr("Maps")
        url: "qrc:/qml/QGroundControl/AppSettings/MapSettings.qml"
        iconUrl: "qrc:/InstrumentValueIcons/globe.svg"
        pageVisible: function() { return true }
    }

    // [ACULA] Remote ID hidden — drone-side compliance tool, not needed in GCS.
    //         Remote ID broadcasts identification data (ID, operator, position)
    //         from the drone hardware — configure on the drone, not here.
    // ListElement { name: qsTr("Remote ID") ... }

    ListElement {
        name: qsTr("Console")
        url: "qrc:/qml/QGroundControl/Controls/AppMessages.qml"
        iconUrl: "qrc:/InstrumentValueIcons/conversation.svg"
        pageVisible: function() { return true }
    }

    // [ACULA] Help hidden — not needed in production GCS
    // ListElement { name: qsTr("Help") ... }

    // Debug-only pages remain conditional
    ListElement {
        name: qsTr("Mock Link")
        url: "qrc:/qml/QGroundControl/AppSettings/MockLink.qml"
        iconUrl: "qrc:/InstrumentValueIcons/drone.svg"
        pageVisible: function() { return ScreenTools.isDebug }
    }

    ListElement {
        name: qsTr("Debug")
        url: "qrc:/qml/QGroundControl/AppSettings/DebugWindow.qml"
        iconUrl: "qrc:/InstrumentValueIcons/bug.svg"
        pageVisible: function() { return ScreenTools.isDebug }
    }
}
