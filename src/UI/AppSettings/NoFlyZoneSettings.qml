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
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.Controls
import QGroundControl.ScreenTools

// [ACULA] No-fly zone (禁航區) management — master overlay toggle, per-category
// (機場 / 限航區) toggle, plus remove / upload of individual KML files.
// Backed by QGroundControl.noFlyZoneManager.
SettingsPage {
    property var _manager: QGroundControl.noFlyZoneManager

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("禁航區圖層")

        QGCCheckBox {
            text:       qsTr("在地圖上顯示禁航區（總開關）")
            checked:    _manager.overlayVisible
            onClicked:  _manager.overlayVisible = checked
        }

        QGCLabel {
            Layout.fillWidth:   true
            wrapMode:           Text.WordWrap
            font.pointSize:     ScreenTools.smallFontPointSize
            text:               qsTr("以紅色半透明區域標示禁航 / 限航範圍。可個別開關下列類別。")
        }
    }

    // One group per category (機場 / 限航區 / 其他)
    Repeater {
        model: _manager.categories

        delegate: SettingsGroupLayout {
            id:                 catGroup
            property var        category: object
            Layout.fillWidth:   true
            heading:            catGroup.category.name + qsTr(" (%1 個檔案)").arg(catGroup.category.files.count)

            QGCCheckBox {
                text:       qsTr("顯示此類別")
                checked:    catGroup.category.visible
                enabled:    _manager.overlayVisible
                onClicked:  catGroup.category.visible = checked
            }

            Repeater {
                model: catGroup.category.files

                delegate: RowLayout {
                    id:                 fileRow
                    property var        zfile: object
                    Layout.fillWidth:   true
                    spacing:            ScreenTools.defaultFontPixelWidth

                    QGCLabel {
                        Layout.fillWidth:   true
                        elide:              Text.ElideRight
                        text:               fileRow.zfile.name + " — " + qsTr("%1 區").arg(fileRow.zfile.ringCount)
                    }

                    QGCButton {
                        text:       qsTr("移除")
                        onClicked:  _manager.removeFile(fileRow.zfile.filePath)
                    }
                }
            }
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth: true

        QGCButton {
            text:       qsTr("上傳 KML…")
            onClicked:  uploadDialog.openForLoad()

            QGCFileDialog {
                id:             uploadDialog
                title:          qsTr("選擇 KML 檔案")
                nameFilters:    [qsTr("KML 檔案 (*.kml)"), qsTr("所有檔案 (*)")]
                onAcceptedForLoad: (file) => {
                    _manager.addKMLFile(file)
                    close()
                }
            }
        }

        QGCLabel {
            Layout.fillWidth:   true
            wrapMode:           Text.WordWrap
            font.pointSize:     ScreenTools.smallFontPointSize
            text:               qsTr("上傳的檔案會依檔名自動歸類（含「機場」歸機場、RCR 歸限航區，其餘歸其他）。")
        }
    }
}
