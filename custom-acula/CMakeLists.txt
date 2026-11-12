message(STATUS "QGC: ACULA GCS custom build")

# Register AculaCorePlugin as the QGC custom plugin class
set_property(DIRECTORY ${CMAKE_SOURCE_DIR}
    APPEND PROPERTY COMPILE_DEFINITIONS
    QGC_CUSTOM_BUILD
    CUSTOMHEADER="AculaCorePlugin.h"
    CUSTOMCLASS=AculaCorePlugin
)

set(CUSTOM_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/src/AculaCorePlugin.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/AculaCorePlugin.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/brand.qrc
    CACHE INTERNAL "" FORCE
)

set(CUSTOM_INCLUDE_DIRECTORIES
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    CACHE INTERNAL "" FORCE
)
