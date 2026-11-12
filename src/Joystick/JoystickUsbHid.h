/****************************************************************************
 *
 * [ACULA] USB HID joystick for the STM32 handheld controller board.
 *
 * Android's input stack cannot see the controller's knob (vendor-defined
 * HID usage), so the Java side (QGCUsbHidJoystick.java) claims the HID
 * interface via the USB Host API and pushes raw reports here (8-byte v2
 * format with BQ2085 battery %, voltage_mv; legacy 6-byte v1 accepted —
 * byte layout documented in QGCUsbHidJoystick.java).
 *
 * This class feeds the raw controls (5 axes + 1 button: X, Y, Z, Rx,
 * Knob) into the generic Joystick machinery, and exposes the handheld's
 * battery state to QML (AculaBatteryIndicator). The RC-override channel
 * map and RC_CHANNELS_OVERRIDE uplink live in the base class and work
 * with every backend (desktop SDL included).
 *
 ****************************************************************************/

#pragma once

#include <QtCore/QLoggingCategory>
#include <QtCore/QMutex>

#include "Joystick.h"

Q_DECLARE_LOGGING_CATEGORY(JoystickUsbHidLog)

class JoystickUsbHid : public Joystick
{
    Q_OBJECT

    // Handheld battery, reported by the STM32 from the BQ2085 gas gauge.
    // Invalid (batteryValid false) until the first v2-format report arrives.
    Q_PROPERTY(bool     batteryValid    READ batteryValid   NOTIFY batteryChanged)
    Q_PROPERTY(int      batteryPercent  READ batteryPercent NOTIFY batteryChanged)
    Q_PROPERTY(double   batteryVoltage  READ batteryVoltage NOTIFY batteryChanged)

public:
    JoystickUsbHid(const QString &name, QObject *parent = nullptr);
    ~JoystickUsbHid();

    bool batteryValid() const;
    int batteryPercent() const;
    double batteryVoltage() const;   // volts

signals:
    void batteryChanged();

public:
    static bool init();
    static void setNativeMethods();
    static QMap<QString, Joystick*> discover();

    // Scales its own raw bytes — QGC stick calibration is unnecessary
    // (defaults are applied in the constructor)…
    bool requiresCalibration() const final { return false; }
    // …and MANUAL_CONTROL stays suppressed (base default, kept explicit).
    bool suppressManualControl() const final { return true; }

private:
    bool _open() final { return true; }
    void _close() final {}
    bool _update() final { return true; }

    bool _getButton(int i) const final;
    int _getAxis(int i) const final;
    bool _getHat(int hat, int i) const final { Q_UNUSED(hat); Q_UNUSED(i); return false; }

    void _handleReport(const quint8 *report, int len);

    static void _jniHidReport(JNIEnv *env, jobject obj, jbyteArray report);
    static void _jniHidJoystickChanged(JNIEnv *env, jobject obj);

    // Raw report state (written by the Java reader thread via JNI)
    mutable QMutex _stateMutex;
    int _axisRaw[5] = {0, 0, 0, 0, 0};   // scaled to ±32767 for the base class
    bool _buttonPressed = false;
    bool _batteryValid = false;
    int _batteryPercent = -1;            // 0..100
    int _batteryVoltageMv = 0;           // millivolts, from uint16 LE bytes 6-7

    static JoystickUsbHid *_instance;

    static constexpr const char *kJoystickName = "ACULA Controller";
};
