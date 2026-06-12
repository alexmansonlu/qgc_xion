#pragma once

#include "QGCCorePlugin.h"
#include "QGCOptions.h"

class AculaOptions;
class AculaCorePlugin;

Q_DECLARE_LOGGING_CATEGORY(AculaLog)

class AculaFlyViewOptions : public QGCFlyViewOptions
{
public:
    explicit AculaFlyViewOptions(AculaOptions *options, QObject *parent = nullptr);

protected:
    bool showMultiVehicleList()       const final { return false; }
    bool guidedBarShowOrbit()         const final { return false; }
    bool guidedBarShowROI()           const final { return false; }
    bool guidedBarShowEmergencyStop() const final { return true;  }
};

class AculaOptions : public QGCOptions
{
public:
    explicit AculaOptions(AculaCorePlugin *plugin, QObject *parent = nullptr);
    ~AculaOptions();

    // Sensor calibration: show compass only (Feature B), hide all others
    bool showSensorCalibrationAccel()    const final { return false; }
    bool showSensorCalibrationAirspeed() const final { return false; }
    bool showSensorCalibrationCompass()  const final { return true;  }
    bool showSensorCalibrationGyro()     const final { return false; }
    bool showSensorCalibrationLevel()    const final { return false; }

    // Simplify setup and UI
    bool showFirmwareUpgrade()   const final { return false; }
    bool multiVehicleEnabled()   const final { return false; }

    QGCFlyViewOptions *flyViewOptions() const final { return _flyViewOptions; }

private:
    AculaFlyViewOptions *_flyViewOptions = nullptr;
};

class AculaCorePlugin : public QGCCorePlugin
{
    Q_OBJECT
public:
    explicit AculaCorePlugin(QObject *parent = nullptr);
    ~AculaCorePlugin();

    static QGCCorePlugin *instance();

    QGCOptions *options() final;
    QString brandImageIndoor()  const final { return QStringLiteral("/res/AculaLogo.png"); }
    QString brandImageOutdoor() const final { return QStringLiteral("/res/AculaLogo.png"); }

private:
    AculaOptions *_options = nullptr;
};
