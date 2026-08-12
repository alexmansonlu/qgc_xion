package org.mavlink.qgroundcontrol;

/* [ACULA] USB HID reader for the STM32 handheld controller board.
 *
 * The controller (VID 0x0483, PID 0x572B) is a USB HID gamepad, but its
 * knob is reported through a vendor-defined HID usage that Android's input
 * stack silently drops — so InputDevice/evdev can never see all controls.
 * This class claims the HID interface directly through the USB Host API
 * (detaching the kernel driver) and streams the raw 6-byte reports to C++:
 *
 *   byte 0  X   0..255   joystick horizontal
 *   byte 1  Y   0..255   joystick vertical
 *   byte 2  Z   0..255   aux axis (switch)
 *   byte 3  Rx  0..255   aux axis
 *   byte 4  bit0 = button
 *   byte 5  knob 0..100  (vendor usage)
 *
 * C++ side: src/Joystick/JoystickUsbHid.{h,cc} registers the natives below
 * onto this class and drives discovery via scan()/isConnected().
 */

import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.hardware.usb.UsbConstants;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbDeviceConnection;
import android.hardware.usb.UsbEndpoint;
import android.hardware.usb.UsbInterface;
import android.hardware.usb.UsbManager;
import android.os.Build;

public class QGCUsbHidJoystick
{
    private static final String TAG = QGCUsbHidJoystick.class.getSimpleName();

    public static final int VENDOR_ID = 0x0483;   // STMicroelectronics
    public static final int PRODUCT_ID = 0x572B;
    private static final int REPORT_LEN = 6;
    private static final int READ_TIMEOUT_MS = 200;

    private static final String ACTION_USB_HID_PERMISSION =
        "org.mavlink.qgroundcontrol.action.USB_HID_PERMISSION";

    private static UsbDevice device;
    private static UsbDeviceConnection connection;
    private static UsbInterface hidInterface;
    private static UsbEndpoint inEndpoint;
    private static Thread readerThread;
    private static volatile boolean running;
    private static boolean permissionReceiverRegistered;
    private static boolean permissionRequested;

    // Registered from C++ (JoystickUsbHid::setNativeMethods)
    private static native void nativeHidReport(byte[] report);
    private static native void nativeHidJoystickChanged();

    /* Find the controller. Returns true if present AND we hold permission
     * (requests permission as a side effect when missing). */
    public static synchronized boolean scan()
    {
        final Context context = QGCActivity.getInstance();
        if (context == null) {
            return false;
        }

        final UsbManager usbManager = (UsbManager) context.getSystemService(Context.USB_SERVICE);
        UsbDevice found = null;
        for (final UsbDevice dev : usbManager.getDeviceList().values()) {
            if ((dev.getVendorId() == VENDOR_ID) && (dev.getProductId() == PRODUCT_ID)) {
                found = dev;
                break;
            }
        }

        if (found == null) {
            closeInternal();
            permissionRequested = false;
            return false;
        }

        if (!usbManager.hasPermission(found)) {
            requestPermission(context, usbManager, found);
            return false;
        }

        device = found;
        permissionRequested = false;
        return true;
    }

    private static void requestPermission(Context context, UsbManager usbManager, UsbDevice dev)
    {
        if (permissionRequested) {
            return; // dialog already pending — don't spam
        }

        if (!permissionReceiverRegistered) {
            final BroadcastReceiver receiver = new BroadcastReceiver() {
                @Override
                public void onReceive(Context ctx, Intent intent) {
                    if (ACTION_USB_HID_PERMISSION.equals(intent.getAction())) {
                        permissionRequested = false;
                        QGCLogger.i(TAG, "HID permission response received");
                        nativeHidJoystickChanged(); // re-kick discovery
                    }
                }
            };
            final IntentFilter filter = new IntentFilter(ACTION_USB_HID_PERMISSION);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED);
            } else {
                context.registerReceiver(receiver, filter);
            }
            permissionReceiverRegistered = true;
        }

        final int intentFlags = (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            ? PendingIntent.FLAG_IMMUTABLE : 0;
        final PendingIntent pi = PendingIntent.getBroadcast(
            context, 0, new Intent(ACTION_USB_HID_PERMISSION), intentFlags);
        permissionRequested = true;
        usbManager.requestPermission(dev, pi);
        QGCLogger.i(TAG, "Requesting HID permission for " + dev.getDeviceName());
    }

    /* Claim the HID interface and start streaming reports. */
    public static synchronized boolean open()
    {
        if (running) {
            return true;
        }
        if (device == null && !scan()) {
            return false;
        }

        final Context context = QGCActivity.getInstance();
        final UsbManager usbManager = (UsbManager) context.getSystemService(Context.USB_SERVICE);

        connection = usbManager.openDevice(device);
        if (connection == null) {
            QGCLogger.w(TAG, "openDevice failed");
            return false;
        }

        hidInterface = null;
        inEndpoint = null;
        for (int i = 0; i < device.getInterfaceCount(); i++) {
            final UsbInterface iface = device.getInterface(i);
            if (iface.getInterfaceClass() != UsbConstants.USB_CLASS_HID) {
                continue;
            }
            for (int e = 0; e < iface.getEndpointCount(); e++) {
                final UsbEndpoint ep = iface.getEndpoint(e);
                if ((ep.getType() == UsbConstants.USB_ENDPOINT_XFER_INT)
                        && (ep.getDirection() == UsbConstants.USB_DIR_IN)) {
                    hidInterface = iface;
                    inEndpoint = ep;
                    break;
                }
            }
            if (hidInterface != null) {
                break;
            }
        }

        if ((hidInterface == null) || (inEndpoint == null)) {
            QGCLogger.w(TAG, "No HID interrupt-IN endpoint found");
            closeInternal();
            return false;
        }

        // force=true detaches the kernel hid driver (input device + hidraw
        // node disappear while we hold the interface — single consumer)
        if (!connection.claimInterface(hidInterface, true)) {
            QGCLogger.w(TAG, "claimInterface failed");
            closeInternal();
            return false;
        }

        running = true;
        readerThread = new Thread(QGCUsbHidJoystick::readerLoop, "AculaHidReader");
        readerThread.setDaemon(true);
        readerThread.start();
        QGCLogger.i(TAG, "HID reader started on " + device.getDeviceName());
        return true;
    }

    private static void readerLoop()
    {
        final byte[] buf = new byte[REPORT_LEN];
        int consecutiveErrors = 0;
        while (running) {
            final int len = connection.bulkTransfer(inEndpoint, buf, REPORT_LEN, READ_TIMEOUT_MS);
            if (len == REPORT_LEN) {
                consecutiveErrors = 0;
                nativeHidReport(buf.clone());
            } else if (len < 0) {
                // timeout or unplug — tolerate timeouts, bail on persistent failure
                if (++consecutiveErrors > 25) {
                    QGCLogger.w(TAG, "HID read failing persistently — stopping reader");
                    running = false;
                    nativeHidJoystickChanged();
                }
            }
        }
    }

    public static synchronized void close()
    {
        closeInternal();
    }

    private static void closeInternal()
    {
        running = false;
        if (readerThread != null) {
            try {
                readerThread.join(500);
            } catch (InterruptedException ignored) {
                Thread.currentThread().interrupt();
            }
            readerThread = null;
        }
        if (connection != null) {
            if (hidInterface != null) {
                connection.releaseInterface(hidInterface);
            }
            connection.close();
        }
        connection = null;
        hidInterface = null;
        inEndpoint = null;
        device = null;
    }

    public static synchronized boolean isConnected()
    {
        return running;
    }
}
