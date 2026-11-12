#include "AculaCorePlugin.h"
#include "QGCLoggingCategory.h"

#include <QtCore/QApplicationStatic>
#include <QtCore/QHash>

#include <array>

QGC_LOGGING_CATEGORY(AculaLog, "gcs.acula.plugin")

Q_APPLICATION_STATIC(AculaCorePlugin, _aculaPluginInstance)

AculaFlyViewOptions::AculaFlyViewOptions(AculaOptions *options, QObject *parent)
    : QGCFlyViewOptions(options, parent)
{
}

AculaOptions::AculaOptions(AculaCorePlugin *plugin, QObject *parent)
    : QGCOptions(parent)
    , _flyViewOptions(new AculaFlyViewOptions(this, this))
{
    Q_UNUSED(plugin)
}

AculaOptions::~AculaOptions() = default;

AculaCorePlugin::AculaCorePlugin(QObject *parent)
    : QGCCorePlugin(parent)
    , _options(new AculaOptions(this, this))
{
}

AculaCorePlugin::~AculaCorePlugin() = default;

QGCCorePlugin *AculaCorePlugin::instance()
{
    return _aculaPluginInstance();
}

QGCOptions *AculaCorePlugin::options()
{
    return _options;
}

void AculaCorePlugin::paletteOverride(const QString &colorName, QGCPalette::PaletteColorInfo_t &colorInfo)
{
    //                         Light theme               Dark theme
    //                         disabled    enabled       disabled    enabled
    using Row = std::array<const char *, 4>;
    static const QHash<QString, Row> colors = {
        { QStringLiteral("window"),              { "#ffffff", "#ffffff",   "#1C1C1E", "#1C1C1E" } },
        { QStringLiteral("windowShade"),         { "#d9d9d9", "#d9d9d9",   "#2C2C2E", "#2C2C2E" } },
        { QStringLiteral("windowShadeDark"),     { "#bdbdbd", "#bdbdbd",   "#141416", "#141416" } },
        { QStringLiteral("warningText"),         { "#cc0808", "#cc0808",   "#FF453A", "#FF453A" } },
        { QStringLiteral("button"),              { "#ffffff", "#ffffff",   "#3A3A3C", "#3A3A3C" } },
        { QStringLiteral("buttonBorder"),        { "#ffffff", "#d9d9d9",   "#48484A", "#48484A" } },
        { QStringLiteral("buttonText"),          { "#9d9d9d", "#000000",   "#A6A6A2", "#ffffff" } },
        { QStringLiteral("buttonHighlight"),     { "#e4e4e4", "#946120",   "#5A1010", "#CC2200" } },
        { QStringLiteral("buttonHighlightText"), { "#2c2c2c", "#ffffff",   "#ffffff", "#ffffff" } },
        // Light-enabled is ACULA red (was upstream #8cb3be) so the red Exit
        // buttons, now palette-driven, look the same in both themes.
        { QStringLiteral("primaryButton"),       { "#585858", "#CC2200",   "#8B1A1A", "#CC2200" } },
        { QStringLiteral("primaryButtonText"),   { "#2c2c2c", "#ffffff",   "#ffffff", "#ffffff" } },
        { QStringLiteral("toolbarBackground"),   { "#ffffff", "#ffffff",   "#1C1C1E", "#1C1C1E" } },
        { QStringLiteral("brandingPurple"),      { "#CC2200", "#CC2200",   "#CC2200", "#CC2200" } },
    };
    const auto it = colors.constFind(colorName);
    if (it == colors.constEnd()) {
        return;
    }
    const Row &row = it.value();
    colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor(row[0]);
    colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled]  = QColor(row[1]);
    colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled]  = QColor(row[2]);
    colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled]   = QColor(row[3]);
}
