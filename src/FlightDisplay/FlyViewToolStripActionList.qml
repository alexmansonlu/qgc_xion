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
import QGroundControl.Controls

// [ACULA GCS] Trimmed ToolStrip — only client-required actions:
// Takeoff (Feature D), Land, RTH (Feature D), Pause, additional actions panel.
// Removed: 3D View (built with VIEWER3D=OFF), PreFlightChecklist, Gripper.

ToolStripActionList {
    id: _root

    signal displayPreFlightChecklist

    model: [
        GuidedActionTakeoff { },
        GuidedActionLand { },
        GuidedActionRTL { },
        GuidedActionPause { },
        FlyViewAdditionalActionsButton { }
    ]
}
