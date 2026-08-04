/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

// [ACULA] No-fly zone (禁航區) KML overlay manager — Phase 1 / deliverable 3.
// Loads CAA no-fly-zone KML files from a writable app-data folder, grouped into
// categories by subfolder (機場 = airports, 限航區 = restricted areas / RCR).
// Each category boundary is assembled from its KML pieces and drawn on the Fly
// view as red polygons. The settings tab toggles the whole overlay, toggles each
// category, and removes / uploads files.

#pragma once

#include <QtCore/QObject>
#include <QtCore/QString>
#include <QtCore/QVariantList>
#include <QtCore/QLoggingCategory>
#include <QtCore/QPointer>

Q_DECLARE_LOGGING_CATEGORY(NoFlyZoneManagerLog)

class QmlObjectListModel;
class Vehicle;

/// One loaded KML file (shown in the settings tab list).
class NoFlyZoneFile : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString name      READ name      CONSTANT)
    Q_PROPERTY(QString filePath  READ filePath  CONSTANT)
    Q_PROPERTY(int     ringCount READ ringCount CONSTANT)

public:
    NoFlyZoneFile(const QString &name, const QString &filePath, int ringCount, QObject *parent = nullptr)
        : QObject(parent), _name(name), _filePath(filePath), _ringCount(ringCount) {}

    QString name() const { return _name; }
    QString filePath() const { return _filePath; }
    int ringCount() const { return _ringCount; }

private:
    QString _name;
    QString _filePath;
    int _ringCount = 0;
};

/// One closed boundary ring (drawn on the map as a filled polygon).
class NoFlyZoneRing : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList path READ path CONSTANT)
    Q_PROPERTY(QString      name READ name CONSTANT)

public:
    NoFlyZoneRing(const QVariantList &path, const QString &name, QObject *parent = nullptr)
        : QObject(parent), _path(path), _name(name) {}

    QVariantList path() const { return _path; }
    QString name() const { return _name; }

private:
    QVariantList _path; // list of QGeoCoordinate
    QString _name;      // owning file's display name (for the breach warning)
};

/// A group of KML files (one subfolder, e.g. 機場 or 限航區) with its own
/// independently-toggleable visibility.
class NoFlyZoneCategory : public QObject
{
    Q_OBJECT
    Q_MOC_INCLUDE("QmlObjectListModel.h")
    Q_PROPERTY(QString             name    READ name    CONSTANT)
    Q_PROPERTY(QmlObjectListModel *files   READ files   CONSTANT)
    Q_PROPERTY(QmlObjectListModel *rings   READ rings   CONSTANT)
    Q_PROPERTY(bool                visible READ visible WRITE setVisible NOTIFY visibleChanged)

public:
    explicit NoFlyZoneCategory(const QString &name, bool visible, QObject *parent = nullptr);

    QString name() const { return _name; }
    QmlObjectListModel *files() { return _files; }
    QmlObjectListModel *rings() { return _rings; }
    bool visible() const { return _visible; }
    void setVisible(bool visible);

signals:
    void visibleChanged();

private:
    QString _name;
    QmlObjectListModel *_files = nullptr;
    QmlObjectListModel *_rings = nullptr;
    bool _visible = true;
};

class NoFlyZoneManager : public QObject
{
    Q_OBJECT
    Q_MOC_INCLUDE("QmlObjectListModel.h")

    Q_PROPERTY(QmlObjectListModel *categories         READ categories         CONSTANT)   ///< NoFlyZoneCategory list
    Q_PROPERTY(bool                overlayVisible     READ overlayVisible     WRITE setOverlayVisible NOTIFY overlayVisibleChanged)
    Q_PROPERTY(bool                vehicleInNoFlyZone READ vehicleInNoFlyZone NOTIFY vehicleStatusChanged)   ///< Active vehicle is inside an enabled zone
    Q_PROPERTY(QString             intrudedZoneName   READ intrudedZoneName   NOTIFY vehicleStatusChanged)   ///< Name of the breached zone (if any)

public:
    explicit NoFlyZoneManager(QObject *parent = nullptr);
    ~NoFlyZoneManager() override;

    static NoFlyZoneManager *instance();

    QmlObjectListModel *categories() { return _categories; }

    bool overlayVisible() const { return _overlayVisible; }
    void setOverlayVisible(bool visible);

    bool vehicleInNoFlyZone() const { return _vehicleInNoFlyZone; }
    QString intrudedZoneName() const { return _intrudedZoneName; }

    /// Absolute path of the writable root folder that holds the category subfolders.
    QString folderPath() const;

    /// Rescan the folders and rebuild the category/file/ring models.
    Q_INVOKABLE void reload();

    /// Copy a user-selected KML file into the auto-classified category folder and reload.
    /// Accepts either a local filesystem path or a file:// URL string.
    Q_INVOKABLE void addKMLFile(const QString &pathOrUrl);

    /// Delete the file with the given absolute path from disk and reload.
    Q_INVOKABLE void removeFile(const QString &filePath);

    static QString categoryVisibleSettingsKey(const QString &categoryName);

signals:
    void overlayVisibleChanged();
    void vehicleStatusChanged();

private:
    void _seedDefaultsIfNeeded();
    void _setActiveVehicle(Vehicle *vehicle);
    void _updateVehicleStatus();
    static bool _parseRings(const QString &filePath, QList<QVariantList> &rings, QString &errorString);
    static QString _classify(const QString &fileName);
    static bool _pointInPath(double lon, double lat, const QVariantList &path);

    QmlObjectListModel *_categories = nullptr;
    bool _overlayVisible = true;

    QPointer<Vehicle> _activeVehicle;
    bool _vehicleInNoFlyZone = false;
    QString _intrudedZoneName;

    static constexpr const char *_settingsGroup        = "NoFlyZones";
    static constexpr const char *_overlayVisibleKey    = "overlayVisible";
    static constexpr const char *_seededKey            = "defaultsSeededV2";
    static constexpr const char *_subFolderName        = "NoFlyZones";
    static constexpr const char *_defaultsResourcePath = ":/NoFlyZoneDefaults";
    static constexpr const char *_categoryAirport      = "機場";
    static constexpr const char *_categoryRestricted   = "限航區";
    static constexpr const char *_categoryOther        = "其他";
};
