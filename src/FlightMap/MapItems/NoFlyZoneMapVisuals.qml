/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtLocation
import QtPositioning

import QGroundControl

/// [ACULA] No-fly zone (禁航區) overlay — draws each assembled KML boundary ring as a
/// semi-transparent red polygon with a solid red border on the Fly view map.
/// Rings are grouped by category (機場 / 限航區); each polygon's visibility is bound
/// to the global overlay toggle AND its category toggle, so toggling either hides
/// the polygons immediately (without tearing down / re-adding map items).
/// Managed by QGroundControl.noFlyZoneManager (see NoFlyZoneManager.cc).
Item {
    id: root

    property var map    ///< The FlightMap these polygons are added to

    property var _manager: QGroundControl.noFlyZoneManager

    Instantiator {
        model: _manager ? _manager.categories : 0

        delegate: Item {
            id: categoryItem
            property var category: object

            Instantiator {
                model: categoryItem.category.rings

                delegate: MapPolygon {
                    z:              QGroundControl.zOrderMapItems - 2  // below mission items / geofence
                    color:          Qt.rgba(1, 0, 0, 0.25)            // semi-transparent red fill (alpha in color, not opacity, so the border stays solid)
                    border.color:   "red"
                    border.width:   2
                    path:           object.path
                    visible:        _manager.overlayVisible && categoryItem.category.visible
                }

                onObjectAdded: (index, obj) => { if (root.map) root.map.addMapItem(obj) }
                onObjectRemoved: (index, obj) => { if (root.map) root.map.removeMapItem(obj) }
            }
        }
    }
}
