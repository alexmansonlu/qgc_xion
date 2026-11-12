message(STATUS "QGC: Xion Control GCS custom build")

# Register XionCorePlugin as the QGC custom plugin class
set_property(DIRECTORY ${CMAKE_SOURCE_DIR}
    APPEND PROPERTY COMPILE_DEFINITIONS
    QGC_CUSTOM_BUILD
    CUSTOMHEADER="XionCorePlugin.h"
    CUSTOMCLASS=XionCorePlugin
)

set(CUSTOM_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/src/XionCorePlugin.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/XionCorePlugin.cc
    # Brand assets under the shared qrc:/brand/ prefix (see brand.qrc)
    ${CMAKE_CURRENT_SOURCE_DIR}/brand.qrc
    CACHE INTERNAL "" FORCE
)

set(CUSTOM_INCLUDE_DIRECTORIES
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    CACHE INTERNAL "" FORCE
)
