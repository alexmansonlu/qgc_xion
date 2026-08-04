/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "NoFlyZoneManager.h"
#include "QmlObjectListModel.h"
#include "SettingsManager.h"
#include "AppSettings.h"
#include "Fact.h"
#include "QGCLoggingCategory.h"
#include "MultiVehicleManager.h"
#include "Vehicle.h"

#include <QtCore/qapplicationstatic.h>
#include <QtCore/QDir>
#include <QtCore/QFile>
#include <QtCore/QFileInfo>
#include <QtCore/QHash>
#include <QtCore/QSettings>
#include <QtCore/QUrl>
#include <QtPositioning/QGeoCoordinate>
#include <QtXml/QDomDocument>

#include <algorithm>

QGC_LOGGING_CATEGORY(NoFlyZoneManagerLog, "qgc.qmlcontrols.noflyzonemanager")

Q_APPLICATION_STATIC(NoFlyZoneManager, _noFlyZoneManager);

// ----------------------------------------------------------------------------
// NoFlyZoneCategory
// ----------------------------------------------------------------------------

NoFlyZoneCategory::NoFlyZoneCategory(const QString &name, bool visible, QObject *parent)
    : QObject(parent)
    , _name(name)
    , _files(new QmlObjectListModel(this))
    , _rings(new QmlObjectListModel(this))
    , _visible(visible)
{
}

void NoFlyZoneCategory::setVisible(bool visible)
{
    if (visible == _visible) {
        return;
    }
    _visible = visible;

    QSettings settings;
    settings.setValue(NoFlyZoneManager::categoryVisibleSettingsKey(_name), _visible);

    emit visibleChanged();
}

// ----------------------------------------------------------------------------
// NoFlyZoneManager
// ----------------------------------------------------------------------------

NoFlyZoneManager *NoFlyZoneManager::instance()
{
    return _noFlyZoneManager();
}

NoFlyZoneManager::NoFlyZoneManager(QObject *parent)
    : QObject(parent)
    , _categories(new QmlObjectListModel(this))
{
    QSettings settings;
    settings.beginGroup(_settingsGroup);
    _overlayVisible = settings.value(_overlayVisibleKey, true).toBool();
    settings.endGroup();

    _seedDefaultsIfNeeded();
    reload();

    // Watch the active vehicle's position to warn when it enters an enabled zone.
    MultiVehicleManager *mvm = MultiVehicleManager::instance();
    (void) connect(mvm, &MultiVehicleManager::activeVehicleChanged, this, &NoFlyZoneManager::_setActiveVehicle);
    _setActiveVehicle(mvm->activeVehicle());
}

NoFlyZoneManager::~NoFlyZoneManager()
{
    _categories->clearAndDeleteContents();
}

QString NoFlyZoneManager::folderPath() const
{
    const QString savePath = SettingsManager::instance()->appSettings()->savePath()->rawValueString();
    return QDir(savePath).filePath(_subFolderName);
}

QString NoFlyZoneManager::categoryVisibleSettingsKey(const QString &categoryName)
{
    return QStringLiteral("%1/categoryVisible/%2").arg(_settingsGroup, categoryName);
}

void NoFlyZoneManager::setOverlayVisible(bool visible)
{
    if (visible == _overlayVisible) {
        return;
    }
    _overlayVisible = visible;

    QSettings settings;
    settings.beginGroup(_settingsGroup);
    settings.setValue(_overlayVisibleKey, _overlayVisible);
    settings.endGroup();

    emit overlayVisibleChanged();
    _updateVehicleStatus();
}

QString NoFlyZoneManager::_classify(const QString &fileName)
{
    const QString lower = fileName.toLower();
    if (fileName.contains(QStringLiteral("機場")) || lower.contains(QStringLiteral("airport"))) {
        return QString::fromUtf8(_categoryAirport);
    }
    if (lower.startsWith(QStringLiteral("rcr")) || fileName.contains(QStringLiteral("限航"))) {
        return QString::fromUtf8(_categoryRestricted);
    }
    return QString::fromUtf8(_categoryOther);
}

void NoFlyZoneManager::_seedDefaultsIfNeeded()
{
    QSettings settings;
    settings.beginGroup(_settingsGroup);
    const bool alreadySeeded = settings.value(_seededKey, false).toBool();
    settings.endGroup();

    if (alreadySeeded) {
        return;
    }

    const QString root = folderPath();
    QDir().mkpath(root);

    // Resource layout mirrors the repo kml/ folder: :/NoFlyZoneDefaults/<category>/*.kml
    const QDir resourceRoot(_defaultsResourcePath);
    const QStringList categories = resourceRoot.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    for (const QString &category : categories) {
        const QDir resourceCat(resourceRoot.filePath(category));
        const QString destCatPath = QDir(root).filePath(category);
        QDir().mkpath(destCatPath);

        const QStringList files = resourceCat.entryList(QStringList() << QStringLiteral("*.kml"), QDir::Files);
        for (const QString &fileName : files) {
            const QString destPath = QDir(destCatPath).filePath(fileName);
            if (!QFile::exists(destPath)) {
                if (QFile::copy(resourceCat.filePath(fileName), destPath)) {
                    QFile::setPermissions(destPath, QFileDevice::ReadOwner | QFileDevice::WriteOwner | QFileDevice::ReadGroup | QFileDevice::ReadOther);
                } else {
                    qCWarning(NoFlyZoneManagerLog) << "Failed to seed default" << category << "/" << fileName;
                }
            }
        }
    }

    settings.beginGroup(_settingsGroup);
    settings.setValue(_seededKey, true);
    settings.endGroup();
}

void NoFlyZoneManager::reload()
{
    _categories->clearAndDeleteContents();

    const QDir root(folderPath());

    // Build the list of category folder names in a sensible, stable order:
    // 機場 first, 限航區 second, then any others alphabetically.
    QStringList catNames = root.entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
    QStringList ordered;
    for (const char *preferred : { _categoryAirport, _categoryRestricted }) {
        const QString name = QString::fromUtf8(preferred);
        if (catNames.removeAll(name) > 0) {
            ordered.append(name);
        }
    }
    ordered.append(catNames);

    // Any loose *.kml directly under the root are grouped as 其他.
    const QStringList looseFiles = root.entryList(QStringList() << QStringLiteral("*.kml"), QDir::Files, QDir::Name);
    if (!looseFiles.isEmpty() && !ordered.contains(QString::fromUtf8(_categoryOther))) {
        ordered.append(QString::fromUtf8(_categoryOther));
    }

    QSettings settings;
    for (const QString &catName : ordered) {
        const bool visible = settings.value(categoryVisibleSettingsKey(catName), true).toBool();
        auto *category = new NoFlyZoneCategory(catName, visible, this);
        (void) connect(category, &NoFlyZoneCategory::visibleChanged, this, &NoFlyZoneManager::_updateVehicleStatus);

        QStringList kmlFiles;
        QDir catDir;
        if (catName == QString::fromUtf8(_categoryOther) && !looseFiles.isEmpty() &&
            !root.exists(catName)) {
            catDir = root;
            kmlFiles = looseFiles;
        } else {
            catDir = QDir(root.filePath(catName));
            kmlFiles = catDir.entryList(QStringList() << QStringLiteral("*.kml"), QDir::Files, QDir::Name);
        }

        for (const QString &fileName : kmlFiles) {
            const QString filePath = catDir.filePath(fileName);

            QList<QVariantList> rings;
            QString errorString;
            if (!_parseRings(filePath, rings, errorString)) {
                qCWarning(NoFlyZoneManagerLog) << "Skipping" << fileName << ":" << errorString;
                continue;
            }

            const QString baseName = QFileInfo(fileName).completeBaseName();
            category->files()->append(new NoFlyZoneFile(baseName, filePath, rings.count()));
            for (const QVariantList &path : rings) {
                category->rings()->append(new NoFlyZoneRing(path, baseName));
            }
        }

        _categories->append(category);
        qCDebug(NoFlyZoneManagerLog) << "Category" << catName << ":" << category->files()->count()
                                     << "file(s)," << category->rings()->count() << "ring(s)";
    }

    _updateVehicleStatus();
}

void NoFlyZoneManager::addKMLFile(const QString &pathOrUrl)
{
    const QUrl url(pathOrUrl);
    const QString srcPath = url.isLocalFile() ? url.toLocalFile() : pathOrUrl;
    if (srcPath.isEmpty() || !QFile::exists(srcPath)) {
        qCWarning(NoFlyZoneManagerLog) << "addKMLFile: source not found" << pathOrUrl;
        return;
    }

    const QString fileName = QFileInfo(srcPath).fileName();
    const QString category = _classify(fileName);
    const QString destCatPath = QDir(folderPath()).filePath(category);
    QDir().mkpath(destCatPath);

    const QString destPath = QDir(destCatPath).filePath(fileName);
    if (QFile::exists(destPath)) {
        QFile::remove(destPath);
    }
    if (!QFile::copy(srcPath, destPath)) {
        qCWarning(NoFlyZoneManagerLog) << "addKMLFile: copy failed" << srcPath << "->" << destPath;
        return;
    }

    reload();
}

void NoFlyZoneManager::removeFile(const QString &filePath)
{
    if (filePath.isEmpty()) {
        return;
    }
    if (!QFile::remove(filePath)) {
        qCWarning(NoFlyZoneManagerLog) << "removeFile: delete failed" << filePath;
    }
    reload();
}

void NoFlyZoneManager::_setActiveVehicle(Vehicle *vehicle)
{
    if (_activeVehicle) {
        (void) disconnect(_activeVehicle, &Vehicle::coordinateChanged, this, &NoFlyZoneManager::_updateVehicleStatus);
    }
    _activeVehicle = vehicle;
    if (_activeVehicle) {
        (void) connect(_activeVehicle, &Vehicle::coordinateChanged, this, &NoFlyZoneManager::_updateVehicleStatus);
    }
    _updateVehicleStatus();
}

void NoFlyZoneManager::_updateVehicleStatus()
{
    bool inside = false;
    QString zoneName;

    if (_overlayVisible && _activeVehicle && _activeVehicle->coordinate().isValid()) {
        const double lon = _activeVehicle->coordinate().longitude();
        const double lat = _activeVehicle->coordinate().latitude();

        for (int c = 0; c < _categories->count() && !inside; c++) {
            auto *category = qobject_cast<NoFlyZoneCategory *>(_categories->get(c));
            if (!category || !category->visible()) {
                continue;
            }
            QmlObjectListModel *ringModel = category->rings();
            for (int r = 0; r < ringModel->count(); r++) {
                auto *ring = qobject_cast<NoFlyZoneRing *>(ringModel->get(r));
                if (ring && _pointInPath(lon, lat, ring->path())) {
                    inside = true;
                    zoneName = ring->name();
                    break;
                }
            }
        }
    }

    if (inside != _vehicleInNoFlyZone || zoneName != _intrudedZoneName) {
        _vehicleInNoFlyZone = inside;
        _intrudedZoneName = zoneName;
        emit vehicleStatusChanged();
        if (inside) {
            qCDebug(NoFlyZoneManagerLog) << "Vehicle entered no-fly zone:" << zoneName;
        }
    }
}

bool NoFlyZoneManager::_pointInPath(double lon, double lat, const QVariantList &path)
{
    // Standard ray-casting point-in-polygon (x = longitude, y = latitude).
    const int n = path.count();
    bool inside = false;
    for (int i = 0, j = n - 1; i < n; j = i++) {
        const QGeoCoordinate pi = path[i].value<QGeoCoordinate>();
        const QGeoCoordinate pj = path[j].value<QGeoCoordinate>();
        const double xi = pi.longitude(), yi = pi.latitude();
        const double xj = pj.longitude(), yj = pj.latitude();
        if (((yi > lat) != (yj > lat)) && (lon < (xj - xi) * (lat - yi) / (yj - yi) + xi)) {
            inside = !inside;
        }
    }
    return inside;
}

bool NoFlyZoneManager::_parseRings(const QString &filePath, QList<QVariantList> &rings, QString &errorString)
{
    rings.clear();
    errorString.clear();

    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly)) {
        errorString = QStringLiteral("Unable to open file: %1").arg(file.errorString());
        return false;
    }

    QDomDocument doc;
    const QDomDocument::ParseResult result = doc.setContent(&file, QDomDocument::ParseOption::Default);
    if (!result) {
        errorString = QStringLiteral("Parse error: %1 (line %2)").arg(result.errorMessage).arg(result.errorLine);
        return false;
    }

    const auto coordsToChain = [](const QString &coordinatesText) -> QList<QGeoCoordinate> {
        QList<QGeoCoordinate> chain;
        const QStringList points = coordinatesText.simplified().split(QLatin1Char(' '), Qt::SkipEmptyParts);
        for (const QString &point : points) {
            const QStringList values = point.split(QLatin1Char(','));
            if (values.size() >= 2) {
                bool lonOk = false, latOk = false;
                const double lon = values[0].toDouble(&lonOk);
                const double lat = values[1].toDouble(&latOk);
                if (lonOk && latOk) {
                    chain.append(QGeoCoordinate(lat, lon));
                }
            }
        }
        return chain;
    };

    // The CAA airport "禁止施放" files store each zone boundary as many separate
    // pieces — straight edges (2-point LineStrings) and curved arcs — that must be
    // joined end-to-end to form one closed shape (a rounded rectangle / stadium).
    // The RCR files store a single already-closed LineString. So: collect every
    // LineString / Polygon outer-boundary as a "chain", then stitch chains whose
    // endpoints meet into closed loops, and fill each loop.
    QList<QList<QGeoCoordinate>> chains;

    const QDomNodeList lineStrings = doc.elementsByTagName(QStringLiteral("LineString"));
    for (int i = 0; i < lineStrings.count(); i++) {
        const QDomNode coordsNode = lineStrings.item(i).namedItem(QStringLiteral("coordinates"));
        if (coordsNode.isNull()) {
            continue;
        }
        const QList<QGeoCoordinate> chain = coordsToChain(coordsNode.toElement().text());
        if (chain.count() >= 2) {
            chains.append(chain);
        }
    }

    // Also support standard <Polygon> outer boundaries, in case a user uploads one.
    const QDomNodeList polygons = doc.elementsByTagName(QStringLiteral("Polygon"));
    for (int i = 0; i < polygons.count(); i++) {
        const QDomNode coordsNode = polygons.item(i)
                                        .namedItem(QStringLiteral("outerBoundaryIs"))
                                        .namedItem(QStringLiteral("LinearRing"))
                                        .namedItem(QStringLiteral("coordinates"));
        if (coordsNode.isNull()) {
            continue;
        }
        const QList<QGeoCoordinate> chain = coordsToChain(coordsNode.toElement().text());
        if (chain.count() >= 2) {
            chains.append(chain);
        }
    }

    if (chains.isEmpty()) {
        errorString = QStringLiteral("No LineString or Polygon boundaries found");
        return false;
    }

    // Endpoints that should connect match to well under a metre in the source data;
    // distinct vertices are >100 m apart. 80 m tolerance is safe.
    constexpr double kTolM = 80.0;
    const auto near = [](const QGeoCoordinate &a, const QGeoCoordinate &b) {
        return a.distanceTo(b) <= kTolM;
    };

    // Group chains into connected components (union-find over shared endpoints).
    QList<int> parent(chains.count());
    for (int i = 0; i < parent.count(); i++) parent[i] = i;
    const auto findRoot = [&](int x) {
        while (parent[x] != x) { parent[x] = parent[parent[x]]; x = parent[x]; }
        return x;
    };
    for (int i = 0; i < chains.count(); i++) {
        for (int j = i + 1; j < chains.count(); j++) {
            const bool touch = near(chains[i].first(), chains[j].first()) || near(chains[i].first(), chains[j].last()) ||
                               near(chains[i].last(),  chains[j].first()) || near(chains[i].last(),  chains[j].last());
            if (touch) parent[findRoot(i)] = findRoot(j);
        }
    }
    QHash<int, QList<int>> components;
    for (int i = 0; i < chains.count(); i++) components[findRoot(i)].append(i);

    // Convex hull (Andrew's monotone chain), x = longitude, y = latitude.
    const auto convexHull = [](QList<QGeoCoordinate> pts) -> QList<QGeoCoordinate> {
        std::sort(pts.begin(), pts.end(), [](const QGeoCoordinate &a, const QGeoCoordinate &b) {
            return a.longitude() < b.longitude() || (a.longitude() == b.longitude() && a.latitude() < b.latitude());
        });
        const int n = pts.count();
        if (n < 3) return pts;
        const auto cross = [](const QGeoCoordinate &o, const QGeoCoordinate &a, const QGeoCoordinate &b) {
            return (a.longitude() - o.longitude()) * (b.latitude() - o.latitude())
                 - (a.latitude() - o.latitude()) * (b.longitude() - o.longitude());
        };
        QList<QGeoCoordinate> h(2 * n);
        int k = 0;
        for (int i = 0; i < n; i++) { while (k >= 2 && cross(h[k - 2], h[k - 1], pts[i]) <= 0) k--; h[k++] = pts[i]; }
        for (int i = n - 2, t = k + 1; i >= 0; i--) { while (k >= t && cross(h[k - 2], h[k - 1], pts[i]) <= 0) k--; h[k++] = pts[i]; }
        h.resize(k > 0 ? k - 1 : 0);
        return h;
    };

    const auto emitRing = [&](const QList<QGeoCoordinate> &loop) {
        if (loop.count() < 3) return;
        QVariantList path;
        for (const QGeoCoordinate &coord : loop) path.append(QVariant::fromValue(coord));
        rings.append(path);
    };

    for (auto it = components.constBegin(); it != components.constEnd(); ++it) {
        const QList<int> &idxs = it.value();

        // Maximum endpoint-node degree in this component.
        QList<QGeoCoordinate> endpoints;
        for (int i : idxs) { endpoints.append(chains[i].first()); endpoints.append(chains[i].last()); }
        int maxDegree = 0;
        QList<bool> counted(endpoints.count(), false);
        for (int a = 0; a < endpoints.count(); a++) {
            if (counted[a]) continue;
            int d = 0;
            for (int b = 0; b < endpoints.count(); b++) if (near(endpoints[a], endpoints[b])) { counted[b] = true; d++; }
            maxDegree = qMax(maxDegree, d);
        }

        if (maxDegree >= 3) {
            // Branching component = interior construction lines (e.g. the airport
            // "禁航區" radii that fan out to a centre point). Stitching them end-to-end
            // would produce sectors (扇形). The real boundary of these convex zones is
            // the outer hull (arc + straight side + arc + straight side = a capsule).
            QList<QGeoCoordinate> pts;
            for (int i : idxs) pts.append(chains[i]);
            emitRing(convexHull(pts));
        } else {
            // Simple cycle (an RCR ring or the outer rectangle): stitch end-to-end and
            // keep the exact shape so concave boundaries are not distorted.
            QList<bool> used(idxs.count(), false);
            QList<QGeoCoordinate> loop = chains[idxs[0]];
            used[0] = true;
            bool extended = true;
            while (extended) {
                extended = false;
                for (int t = 1; t < idxs.count(); t++) {
                    if (used[t]) continue;
                    const QList<QGeoCoordinate> &c = chains[idxs[t]];
                    if (near(loop.last(), c.first()))       { for (int k = 1; k < c.count(); k++) loop.append(c[k]); }
                    else if (near(loop.last(), c.last()))   { for (int k = c.count() - 2; k >= 0; k--) loop.append(c[k]); }
                    else if (near(loop.first(), c.last()))  { for (int k = c.count() - 2; k >= 0; k--) loop.prepend(c[k]); }
                    else if (near(loop.first(), c.first())) { for (int k = 1; k < c.count(); k++) loop.prepend(c[k]); }
                    else continue;
                    used[t] = true;
                    extended = true;
                }
            }
            emitRing(loop);
        }
    }

    if (rings.isEmpty()) {
        errorString = QStringLiteral("No closed boundary could be assembled");
        return false;
    }

    return true;
}
