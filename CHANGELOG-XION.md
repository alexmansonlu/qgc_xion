# XionGCS Changelog

Xion Control ground control station. Fork of QGroundControl (tracking QGC
v5.0.8), built on top of the ACULA GCS work. Repository:
`github.com/alexmansonlu/qgc_xion`, branch `main`.

Versioning: `MAJOR.MINOR.PATCH` of *our* product, independent of the upstream
QGC version we track. ACULA keeps its own history in `CHANGELOG-ACULA.md`.

## Building (Ubuntu 22.04, Qt 6.8.3)

```bash
cmake -B build-xion -G Ninja -DCMAKE_BUILD_TYPE=Debug \
      -DCMAKE_PREFIX_PATH=$HOME/Qt/6.8.3/gcc_64 \
      -DQT_DIR=$HOME/Qt/6.8.3/gcc_64/lib/cmake/Qt6 \
      -DQGC_CUSTOM_DIR=custom-xion
cmake --build build-xion
./build-xion/Debug/XionGCS
```

`QGC_CUSTOM_DIR` picks the product: `custom-xion` (default), `custom-acula`,
or empty for stock QGroundControl.

---

## v0.1.0 — in progress

**Stage 1: Xion Control branding, running on Ubuntu.**

### Brand layers (new)

- **One source tree, several products.** The brand is chosen at configure time
  with `-DQGC_CUSTOM_DIR=<dir>`. Each brand directory provides its own
  `CustomOverrides.cmake` (app name, organisation, package IDs, icons), a
  `QGCCorePlugin` subclass, and a `brand.qrc` that exposes the same set of
  images under `qrc:/brand/` (`AppIcon`, `ToolbarLogoDark/Light`, `MapMarker`,
  `LogoDark/Light`, `MarkDark/Light`). Shared QML refers only to `/brand/...`,
  so it never names a specific product. (`CMakeLists.txt`)
- **ACULA moved into `custom-acula/`.** Its palette edits, which had been made
  directly in `src/QmlControls/QGCPalette.cc`, now live in
  `AculaCorePlugin::paletteOverride()`. `QGCPalette.cc` is back to upstream.
  ACULA still builds and looks the same: `-DQGC_CUSTOM_DIR=custom-acula`.

### Xion Control brand (`custom-xion/`)

- **App identity:** XionGCS, organisation "XionControl", package and bundle ID
  `com.xixiong.xiongcs`. *These names are placeholders and still need
  confirming.*
- **Palette** taken from the company logo, applied through
  `XionCorePlugin::paletteOverride()`:
  - near-black toolbar `#040707`; grey windows and panels (`#121615`,
    `#1E2322`, `#2C3230`)
  - brand green `#16A751` for branding accents
  - dark green `#0F7A3B` for buttons and highlights. White text on it has
    about 5.4:1 contrast; on the brighter brand green it would only be about
    3.2:1.
  - orange `#F28C28` for small highlights: map buttons, map indicators and the
    mission trajectory line
  - status colours (red, green, yellow and so on) are left at the QGC
    defaults, so warnings keep their usual meaning.
  - Light and dark themes are both defined.
- **Logos and icons** are generated from the company logo (`logo-06.png`):
  app icon (PNG + Windows `.ico`), full logo, square mark, toolbar lockup,
  and dark-theme variants with white ink.
- **Logo at the top right of the fly-view toolbar.** The full XION CONTROL
  lockup shows when there is room. On narrower windows it falls back to the
  square mark, so the logo is always visible. (`FlyViewToolBar.qml`)

### Shared UI changes (all brands)

- Exit buttons (main window and plan view) use the palette's
  `primaryButton` / `primaryButtonText` colours instead of hard-coded red.
  ACULA keeps its red by setting those colours to `#CC2200`.
- Mission geometry lines (polylines, corridor scan, fixed-wing and VTOL
  landing patterns) use the palette's `mapMissionTrajectory` colour instead of
  hard-coded `#be781c`.
- The GCS map marker (`/brand/MapMarker.png`) keeps its aspect ratio.
- The Linux window icon comes from the brand layer (`:/brand/AppIcon.png`).
- The navigation-menu arrow "▼" uses the theme text colour, so it can be seen
  in the light theme.

### Build

- **Fixed a fresh-checkout build failure.** `libevents` was fetched from its
  moving `main` branch. The commit after `077677a` needs MAVLink helpers that
  are newer than our `c_library_v2` (`mavlink_msg_target_field` and others),
  so `receive.h` failed to compile. It is now pinned to `077677a`.
- `ulog_cpp` and `SDL_GameControllerDB` are pinned to fixed commits too
  (`PX4-GPSDrivers` was already pinned), so builds can be reproduced.

### Inherited from ACULA v0.2.3 (work in progress)

- Controller battery level reported over HID (v2 report layout).

### Known issues / not yet done

- Xion currently inherits ACULA behaviour that may not suit it:
  - the extra toolbar indicators
  - the Taiwan no-fly-zone overlay
  - the hidden Joystick setup page
  - MANUAL_CONTROL is suppressed, so a normal gamepad cannot fly the
    vehicle

  These are still to be decided, and the plan is to make them per-brand
  options.
- Android icons and splash screen are still ACULA's (`android/res`).
- Packaging still to do:
  - Ubuntu AppImage (needs `patchelf`)
  - macOS
  - Windows
  - Android
- The units first-run prompt still appears on every fresh settings file.
