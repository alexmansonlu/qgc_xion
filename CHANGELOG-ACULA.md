# AculaGCS Changelog

Custom ground control station for the ACULA handheld controller
(deliverable 3). Fork of QGroundControl, branch `rb3-custom-v5`.

Versioning: `MAJOR.MINOR.PATCH` of *our* product, independent of the upstream
QGC version we track (currently QGC v5.0.8).

---

## v0.1.0 — 2026-08-04

**First version that runs on the real RB3 Gen 2 hardware.** Prior work ran only
on the macOS desktop build; this release makes the Android APK boot, render,
stay alive, and talk to a flight controller on the QCS6490 board.

### Platform / RB3 bring-up (new in this release)

- **Fixed fatal graphics crash on the board.** The Android build forced the
  Vulkan RHI backend (a workaround for a gfxstream bug in ARM64 emulators on
  Apple Silicon). On the real device the Android-11-era vendor gralloc cannot
  allocate the AHardwareBuffer formats (`0x38`/`0x3b`) that Android-15 Vulkan
  requests, so every allocation failed and the app died ~10 s after launch —
  a freeze with no Java exception and no tombstone. The backend is now chosen
  at runtime: Vulkan only when the build fingerprint says emulator, OpenGL ES
  on real hardware. (`src/main.cc`, `src/QGCApplication.cc`)
- **Fixed USB device enumeration aborting when foreign USB devices are
  present.** `availableDevicesInfo()` called `UsbDevice.getSerialNumber()`
  without permission for devices the user never approved (USB-Ethernet
  adapter, HID receiver). The resulting `SecurityException` propagated out of
  the enumeration loop and discarded the *entire* device list — including the
  flight controller — so the FC could never connect despite its permission
  dialogs appearing. Serial number is now optional per device, and each device
  is enumerated defensively. This also matters for the production controller,
  where the R405LQ datalink and the STM32 joystick board share the USB bus.
  (`android/src/org/mavlink/qgroundcontrol/QGCUsbSerialManager.java`)
- Verified on hardware: MAVLink connection to a CubePilot CubeOrange+ over USB
  via the Android USB Host API; rendering at 1920×1080 with 0.56 % janky
  frames (90th-percentile frame time 8 ms).

### Branding and UI

- ACULA branding throughout: app name, logo, menu icons, application icon.
- ACULA logo used as the vehicle map marker (black rounded badge).
- Toolbar restructured: simplified dropdown indicator, tightened spacing,
  smaller menu icons.
- Main menu: explicit **Plan Flight** entry (mission planning + geofence
  editor), plus exit button, autonomous-flight placeholder and remote-support
  entries.

### Features

- **No-fly zones (禁航區)**: `NoFlyZoneManager` with map overlay
  (`NoFlyZoneMapVisuals.qml`) and a settings page — master toggle plus
  per-category control. Ships bundled KML data for Taiwan airports and
  restricted-airspace zones.
- **Camera resolution UI** (feature C): setup page under Vehicle Setup →
  Camera (4K / FHD / HD selection; wiring to the real camera definition
  pending ACULA hardware).
- **Consolidated joystick / 搖桿 settings page**, including a global
  "enable joystick by default" preference — a vehicle with no stored
  per-vehicle value now falls back to it, so the operator can configure the
  controller with no aircraft connected.
- Settings pages cleaned up and reorganised.

### Localisation

- Traditional Chinese (zh_TW) throughout, converted from Simplified sources,
  with locale handling fixed.
- Translated GPS popup and settings tab content.
- Fixed duplicate `<translation/>` entries that silently dropped the settings
  and GPS translations.

### Upstream fixes carried in the fork

- `GPSDriverUBX` constructor API mismatch against the px4-gpsdrivers submodule.
- Camera resolution panel divider crash.
- Build fixes for Qt 6.9+.

### Known issues

- **Mouse map-dragging on Android intermittently fails to engage.** The map
  pans through a custom `MultiPointTouchArea` whose drag only starts on
  `onGestureStarted`; the mouse path on Android is an untested upstream corner
  and is easily disturbed (measured 100–250 ms stalls in the raw input stream
  from a 2.4 GHz receiver sitting next to a USB-3 Ethernet dongle). **Touch
  input is unaffected** — verified smooth via injected touch events — and the
  product is touch-only, so this is a bench-only annoyance. Workarounds: wired
  mouse, or move the wireless receiver away from USB-3 devices.
- Android USB permission grants are per *device instance*: replugging the
  flight controller invalidates the previous grant and the dialog must be
  approved again. Upstream behaviour, not fork-specific.
- Camera resolution UI is not yet wired to a real camera definition.
- Autonomous flight page is a placeholder, per spec.

### Build / deploy

Toolchain and commands: see `CLAUDE.md`. Desktop Linux and Android ARM64
builds both verified from this tree. APKs from Gradle are unsigned — sign with
the debug keystore before `adb install` (procedure in `CLAUDE.md`). Local
no-hardware testing (SITL + fake RTSP): see `LOCAL_TEST_PIPELINE.md`.

---

## v0.1.1 — in progress

_Add entries here as work lands._
