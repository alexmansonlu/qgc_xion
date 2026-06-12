#include "AculaCorePlugin.h"
#include "QGCLoggingCategory.h"

#include <QtCore/QApplicationStatic>

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
