/****************************************************************************
 *
 * [ACULA] USB HID joystick — see JoystickUsbHid.h.
 *
 ****************************************************************************/

#include "JoystickUsbHid.h"
#include "JoystickManager.h"
#include "AndroidInterface.h"
#include "QGCLoggingCategory.h"

#include <QtCore/QJniEnvironment>
#include <QtCore/QJniObject>

QGC_LOGGING_CATEGORY(JoystickUsbHidLog, "qgc.joystick.usbhid")

JoystickUsbHid *JoystickUsbHid::_instance = nullptr;

static constexpr const char *kJniHidClassName = "org/mavlink/qgroundcontrol/QGCUsbHidJoystick";

JoystickUsbHid::JoystickUsbHid(const QString &name, QObject *parent)
    : Joystick(name, 5 /*axes: X Y Z Rx Knob*/, 1 /*buttons*/, 0 /*hats*/, parent)
{
    // Mark calibrated with defaults (same pattern as SDL game controllers):
    // without this the RC-output enable stays locked behind the stick wizard.
    _setDefaultCalibration();

    _instance = this;

    qCDebug(JoystickUsbHidLog) << "created" << name;
}

JoystickUsbHid::~JoystickUsbHid()
{
    _instance = nullptr;
    QJniObject::callStaticMethod<void>(kJniHidClassName, "close", "()V");
}

bool JoystickUsbHid::init()
{
    return true;
}

QMap<QString, Joystick*> JoystickUsbHid::discover()
{
    static QMap<QString, Joystick*> ret;

    const bool present = QJniObject::callStaticMethod<jboolean>(kJniHidClassName, "scan", "()Z");
    (void) AndroidInterface::cleanJavaException();

    if (present) {
        const bool opened = QJniObject::callStaticMethod<jboolean>(kJniHidClassName, "open", "()Z");
        (void) AndroidInterface::cleanJavaException();
        if (opened && !ret.contains(kJoystickName)) {
            ret[kJoystickName] = new JoystickUsbHid(kJoystickName);
        } else if (!opened) {
            ret.remove(kJoystickName);
        }
    } else {
        ret.remove(kJoystickName);
    }

    return ret;
}

bool JoystickUsbHid::_getButton(int i) const
{
    QMutexLocker lock(&_stateMutex);
    return (i == 0) ? _buttonPressed : false;
}

int JoystickUsbHid::_getAxis(int i) const
{
    QMutexLocker lock(&_stateMutex);
    return ((i >= 0) && (i < 5)) ? _axisRaw[i] : 0;
}

/* Runs on the Java reader thread (~87 Hz). Only stores state — the base
 * class polling loop consumes it via _getAxis/_getButton and drives the
 * monitors and the RC-override uplink. batteryChanged is emitted from this
 * thread only when the displayed value moves (queued into the QML thread). */
void JoystickUsbHid::_handleReport(const quint8 *report, int len)
{
    if (len < 6) {
        return;
    }

    bool battChanged = false;
    {
        QMutexLocker lock(&_stateMutex);

        // Base-class axis convention: ±32767
        for (int i = 0; i < 4; i++) {       // X Y Z Rx: 0..255 (Rx: 0/127/255 switch on v2 fw)
            _axisRaw[i] = static_cast<int>((report[i] - 127.5f) / 127.5f * 32767.f);
        }

        if (len >= 8) {
            // v2 firmware: knob is byte 2 (z, 0..255); bytes 5-7 = battery
            _axisRaw[4] = static_cast<int>((report[2] - 127.5f) / 127.5f * 32767.f);

            const int percent   = qMin<int>(report[5], 100);
            const int voltageMv = report[6] | (report[7] << 8);   // uint16 little-endian
            // Re-emit only when the displayed reading moves (1 % / 0.1 V steps)
            battChanged = !_batteryValid
                          || (percent != _batteryPercent)
                          || ((voltageMv / 100) != (_batteryVoltageMv / 100));
            _batteryValid = true;
            _batteryPercent = percent;
            _batteryVoltageMv = voltageMv;
        } else {
            // v1 firmware: knob is byte 5 (0..100), no battery data
            _axisRaw[4] = static_cast<int>((report[5] - 50.f) / 50.f * 32767.f);
        }

        _buttonPressed = (report[4] & 0x01);
    }

    if (battChanged) {
        emit batteryChanged();
    }
}

bool JoystickUsbHid::batteryValid() const
{
    QMutexLocker lock(&_stateMutex);
    return _batteryValid;
}

int JoystickUsbHid::batteryPercent() const
{
    QMutexLocker lock(&_stateMutex);
    return _batteryPercent;
}

double JoystickUsbHid::batteryVoltage() const
{
    QMutexLocker lock(&_stateMutex);
    return _batteryVoltageMv / 1000.0;
}

/*===========================================================================*/
/* JNI                                                                       */
/*===========================================================================*/

void JoystickUsbHid::_jniHidReport(JNIEnv *env, jobject obj, jbyteArray report)
{
    Q_UNUSED(obj);

    if (!_instance) {
        return;
    }

    quint8 buf[8];
    const jsize len = env->GetArrayLength(report);
    if ((len < 6) || (len > 8)) {
        return;
    }
    env->GetByteArrayRegion(report, 0, len, reinterpret_cast<jbyte*>(buf));

    _instance->_handleReport(buf, len);
}

void JoystickUsbHid::_jniHidJoystickChanged(JNIEnv *env, jobject obj)
{
    Q_UNUSED(env); Q_UNUSED(obj);

    qCDebug(JoystickUsbHidLog) << "hid joystick changed — re-discovering";
    emit JoystickManager::instance()->updateAvailableJoysticksSignal();
}

void JoystickUsbHid::setNativeMethods()
{
    qCDebug(JoystickUsbHidLog) << "Registering Native Functions";

    static const JNINativeMethod javaMethods[] {
        {"nativeHidReport", "([B)V", reinterpret_cast<void*>(_jniHidReport)},
        {"nativeHidJoystickChanged", "()V", reinterpret_cast<void*>(_jniHidJoystickChanged)},
    };

    (void) AndroidInterface::cleanJavaException();

    QJniEnvironment jniEnv;
    jclass objectClass = jniEnv->FindClass(kJniHidClassName);
    if (!objectClass) {
        (void) AndroidInterface::cleanJavaException();
        qCWarning(JoystickUsbHidLog) << "Couldn't find class:" << kJniHidClassName;
        return;
    }

    const jint val = jniEnv->RegisterNatives(objectClass, javaMethods, std::size(javaMethods));
    if (val < 0) {
        qCWarning(JoystickUsbHidLog) << "Error registering methods:" << val;
    } else {
        qCDebug(JoystickUsbHidLog) << "Native Functions Registered";
    }

    (void) AndroidInterface::cleanJavaException();
}
