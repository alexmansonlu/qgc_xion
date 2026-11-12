#include "XionCorePlugin.h"
#include "QGCLoggingCategory.h"

#include <QtCore/QApplicationStatic>
#include <QtCore/QHash>

#include <array>

QGC_LOGGING_CATEGORY(XionLog, "gcs.xion.plugin")

Q_APPLICATION_STATIC(XionCorePlugin, _xionPluginInstance)

namespace {

// ---------------------------------------------------------------------------
// Xion Control brand palette
//
//   Base black   #040707  (logo)        Grey 1  #1E2322   Grey 3  #4A524F
//   Panel        #121615                Grey 2  #2C3230   Muted   #A3ABA7
//   Xion green   #16A751  (logo)  accents on dark: selection, focus, outlines
//   Dark green   #0F7A3B          filled buttons with WHITE text (5.4:1 contrast;
//                                 white on the logo green is only 3.2:1)
//   Deep green   #0A4D27          subtle fills, selected rows
//   Orange       #F28C28          sparing accent: mission path, map highlights
//
// Status colours (colorRed / colorYellow / colorOrange / colorGreen) are NOT
// overridden: they carry safety meaning and must stay distinct from branding.
// ---------------------------------------------------------------------------

//                     Light theme               Dark theme
//                     disabled    enabled       disabled    enabled
using Row = std::array<const char *, 4>;

const QHash<QString, Row> &xionColors()
{
    static const QHash<QString, Row> colors = {
        { QStringLiteral("window"),              { "#ffffff", "#ffffff",   "#121615", "#121615" } },
        { QStringLiteral("windowShadeLight"),    { "#909090", "#828282",   "#4A524F", "#3C4341" } },
        { QStringLiteral("windowShade"),         { "#e3e7e5", "#e3e7e5",   "#1E2322", "#1E2322" } },
        { QStringLiteral("windowShadeDark"),     { "#c9cfcc", "#c9cfcc",   "#0A0D0C", "#0A0D0C" } },
        { QStringLiteral("text"),                { "#9d9d9d", "#000000",   "#6B7370", "#ffffff" } },
        { QStringLiteral("warningText"),         { "#cc0808", "#cc0808",   "#FF453A", "#FF453A" } },
        { QStringLiteral("button"),              { "#ffffff", "#ffffff",   "#2C3230", "#2C3230" } },
        { QStringLiteral("buttonBorder"),        { "#ffffff", "#c9cfcc",   "#3A403E", "#4A524F" } },
        { QStringLiteral("buttonText"),          { "#9d9d9d", "#000000",   "#6B7370", "#ffffff" } },
        { QStringLiteral("buttonHighlight"),     { "#e4e4e4", "#0F7A3B",   "#0A4D27", "#0F7A3B" } },
        { QStringLiteral("buttonHighlightText"), { "#2c2c2c", "#ffffff",   "#A3ABA7", "#ffffff" } },
        { QStringLiteral("primaryButton"),       { "#9fb5aa", "#0F7A3B",   "#0A4D27", "#0F7A3B" } },
        { QStringLiteral("primaryButtonText"),   { "#e3e7e5", "#ffffff",   "#A3ABA7", "#ffffff" } },
        { QStringLiteral("mapButton"),           { "#585858", "#040707",   "#585858", "#040707" } },
        { QStringLiteral("mapButtonHighlight"),  { "#585858", "#F28C28",   "#585858", "#F28C28" } },
        { QStringLiteral("mapIndicator"),        { "#585858", "#F28C28",   "#585858", "#F28C28" } },
        { QStringLiteral("mapIndicatorChild"),   { "#585858", "#9A5A1C",   "#585858", "#9A5A1C" } },
        { QStringLiteral("missionItemEditor"),   { "#585858", "#d6efe0",   "#585858", "#0A4D27" } },
        { QStringLiteral("toolStripHoverColor"), { "#585858", "#9D9D9D",   "#585858", "#0F7A3B" } },
        { QStringLiteral("toolbarBackground"),   { "#ffffff", "#ffffff",   "#040707", "#040707" } },
        { QStringLiteral("groupBorder"),         { "#bbbbbb", "#bbbbbb",   "#3A403E", "#3A403E" } },

        // Non-themed (same in both themes)
        // brandingPurple = toolbar status block while disconnected: neutral grey,
        // so "disconnected" never reads as "ready" (green) or as an alarm (red).
        { QStringLiteral("brandingPurple"),      { "#3A403E", "#3A403E",   "#3A403E", "#3A403E" } },
        { QStringLiteral("brandingBlue"),        { "#16A751", "#16A751",   "#16A751", "#16A751" } },
        { QStringLiteral("mapMissionTrajectory"),{ "#F28C28", "#F28C28",   "#F28C28", "#F28C28" } },
    };
    return colors;
}

} // namespace

XionOptions::XionOptions(XionCorePlugin *plugin, QObject *parent)
    : QGCOptions(parent)
{
    Q_UNUSED(plugin)
}

XionOptions::~XionOptions() = default;

XionCorePlugin::XionCorePlugin(QObject *parent)
    : QGCCorePlugin(parent)
    , _options(new XionOptions(this, this))
{
}

XionCorePlugin::~XionCorePlugin() = default;

QGCCorePlugin *XionCorePlugin::instance()
{
    return _xionPluginInstance();
}

QGCOptions *XionCorePlugin::options()
{
    return _options;
}

void XionCorePlugin::paletteOverride(const QString &colorName, QGCPalette::PaletteColorInfo_t &colorInfo)
{
    const auto it = xionColors().constFind(colorName);
    if (it == xionColors().constEnd()) {
        return;
    }
    const Row &row = it.value();
    colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor(row[0]);
    colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled]  = QColor(row[1]);
    colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled]  = QColor(row[2]);
    colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled]   = QColor(row[3]);
}
