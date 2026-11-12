# Xion Control GCS — brand overrides
# Included by the root CMakeLists.txt when QGC_CUSTOM_DIR=custom-xion (the default).
# Every product-identity string lives here: change a name/ID in one place.

# QGC_APP_NAME is also the CMake project/target name and the binary name — no spaces.
set(QGC_APP_NAME        "XionGCS"                                   CACHE STRING "" FORCE)
set(QGC_APP_DESCRIPTION "Xion Control Ground Control Station"       CACHE STRING "" FORCE)
set(QGC_APP_COPYRIGHT   "Copyright 2026 Xion Control. All rights reserved." CACHE STRING "" FORCE)
# Org name + app name form the settings path (~/.config/XionControl/XionGCS.ini),
# so Xion and ACULA keep separate settings on the same machine.
set(QGC_ORG_NAME        "XionControl"                               CACHE STRING "" FORCE)
set(QGC_ORG_DOMAIN      "xixiong.com"                               CACHE STRING "" FORCE)
set(QGC_PACKAGE_NAME    "com.xixiong.xiongcs"                       CACHE STRING "" FORCE)
set(QGC_ANDROID_PACKAGE_NAME "${QGC_PACKAGE_NAME}"                  CACHE STRING "" FORCE)
set(QGC_MACOS_BUNDLE_ID "${QGC_PACKAGE_NAME}"                       CACHE STRING "" FORCE)

# Platform icons
set(QGC_APPIMAGE_ICON_PATH "${CMAKE_CURRENT_LIST_DIR}/../res/XionAppIcon128.png" CACHE FILEPATH "" FORCE)
set(QGC_WINDOWS_ICON_PATH  "${CMAKE_CURRENT_LIST_DIR}/../res/XionAppIcon.ico"    CACHE FILEPATH "" FORCE)
