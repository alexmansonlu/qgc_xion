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

## v0.1.1 — 2026-08-04

Fly-view layout rework for the handheld: all flight information moves from the
map overlay into the top toolbar, and the map gains on-screen zoom.

### Fly view

- **Bottom-right information stack hidden.** The telemetry values bar and the
  instrument panel no longer overlay the map; everything they showed now lives
  in the toolbar. The components stay instantiated (just invisible) so upstream
  merges remain clean.
- **Map zoom +/- buttons now shown on touch devices.** The buttons already
  existed next to the scale bar but upstream hides them whenever
  `ScreenTools.isMobile` is true, assuming pinch-zoom suffices. The handheld
  needs both.

### Toolbar

New indicator set, left to right: flight mode (unchanged) → GPS → link signal
→ temperature → battery → flight telemetry. Upstream's separate telemetry-RSSI
and RC-RSSI indicators are folded into the new signal indicator, and the stock
battery indicator is replaced.

- **GPS** — unchanged upstream behaviour (satellite count over HDOP, tap for
  detail), now drawn with the ACULA satellite icon.
- **Link signal** (new) — signal icon plus link quality percentage. Uses RC
  RSSI when available and falls back to telemetry RSSI, mapping −120…−50 dBm
  onto 0…100 %. Tap for both raw values.
- **Temperature** (new) — autopilot IMU temperature in °C.
- **Battery** (new) — two rows, aircraft over controller, each formatted
  `xx%(yy.yV)`, coloured amber below 40 % and red below 20 %. **The controller
  row is placeholder data** until the BQ24810/BQ2085 handheld battery board is
  readable (deliverables 1–2); the wiring point is marked in the source.
- **Flight telemetry** (new) — three two-row columns:
  相對高度/上升速度, home點距離/總航程, 飛行速度/飛行時間. Flight time is
  rendered m:ss to stay narrow. Tap for a labelled breakdown of all six.

### Layout rules applied to the new indicators

- **Fixed geometry.** Every value sits in a constant-width slot, so a changing
  reading never moves its icon or shifts neighbouring indicators — the whole
  toolbar stays still while numbers update.
- Values are left-aligned inside their slot so each number sits directly beside
  its icon; icon-to-value spacing tightened to 0.35 character widths.
- Generous separation between groups: 4 character widths between telemetry
  columns, 4.5 between whole indicators.
- Icons are drawn through `QGCColoredImage`, tinted with the palette text
  colour. The supplied PNG artwork ranges from near-black (`clock`) to
  near-white (`satellite`, `uav`), so untinted icons were invisible against the
  toolbar on one theme or the other.

### Build

- **Fixed the project version breaking on any prefixed git tag.**
  `cmake/Git.cmake` derived the CMake project version by deleting every letter
  `v` from `git describe` output and assuming a bare `MAJOR.MINOR.PATCH`
  remained. The `acula-v0.1.0` release tag therefore produced `acula-0.1.0`,
  which `project(VERSION)` rejects — configure failed outright. The version is
  now extracted by regex, so any tag naming works. Side effect: the application
  now reports its ACULA product version (0.1.x) rather than an upstream number.
- `APMFirmwarePlugin` matched the stock battery indicator with a substring test
  that also matched `AculaBatteryIndicator.qml`, silently replacing ours; it
  now matches the full resource path.

### Known issues

Carried over from v0.1.0 (mouse map-drag, per-instance USB permissions, camera
resolution page not wired, autonomous placeholder). Additionally:

- 返航距離 from the original spec is rendered as **總航程 / total flight
  distance**. Literally "return distance" is the same value as home點距離, so
  the second slot would have duplicated the first; confirm which reading is
  wanted.
- Icon-to-value assignments in the telemetry block were chosen pragmatically
  from the supplied icon set and are easy to reshuffle.

---

## v0.1.2 — in progress

_Add entries here as work lands._
