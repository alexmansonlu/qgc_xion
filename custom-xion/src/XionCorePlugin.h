#pragma once

#include "QGCCorePlugin.h"
#include "QGCOptions.h"

class XionCorePlugin;

Q_DECLARE_LOGGING_CATEGORY(XionLog)

class XionOptions : public QGCOptions
{
public:
    explicit XionOptions(XionCorePlugin *plugin, QObject *parent = nullptr);
    ~XionOptions();

    // Stock QGC options for now. Product restrictions (hidden pages, single
    // vehicle, ...) go here as overrides — see AculaOptions for examples.
};

class XionCorePlugin : public QGCCorePlugin
{
    Q_OBJECT
public:
    explicit XionCorePlugin(QObject *parent = nullptr);
    ~XionCorePlugin();

    static QGCCorePlugin *instance();

    QGCOptions *options() final;

    // Indoor = dark palette, outdoor = light palette
    QString brandImageIndoor()  const final { return QStringLiteral("/brand/ToolbarLogoDark.png"); }
    QString brandImageOutdoor() const final { return QStringLiteral("/brand/ToolbarLogoLight.png"); }

    /// Xion Control palette: black / grey / green, orange as a sparing accent.
    void paletteOverride(const QString &colorName, QGCPalette::PaletteColorInfo_t &colorInfo) final;

private:
    XionOptions *_options = nullptr;
};
