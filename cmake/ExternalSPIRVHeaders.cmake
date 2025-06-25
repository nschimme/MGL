# SPIRV-Headers
ExternalProject_Add(spirv_headers_project
    GIT_REPOSITORY https://github.com/KhronosGroup/SPIRV-Headers.git
    GIT_TAG main # Or a specific commit/tag
    SOURCE_DIR ${CMAKE_BINARY_DIR}/external/spirv_headers
    BINARY_DIR ${CMAKE_BINARY_DIR}/external/spirv_headers-build
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/external/spirv_headers-install
        -DSPIRV_HEADERS_SKIP_INSTALL=OFF
    BUILD_COMMAND "" # Header-only, but CMake step might generate files
    INSTALL_COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_BINARY_DIR}/external/spirv_headers/include ${CMAKE_BINARY_DIR}/external/spirv_headers-install/include
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)

set(SPIRV_HEADERS_INSTALL_DIR ${CMAKE_BINARY_DIR}/external/spirv_headers-install)

# Interface target for include directories
add_library(SPIRV-Headers INTERFACE IMPORTED GLOBAL)
target_include_directories(SPIRV-Headers INTERFACE ${SPIRV_HEADERS_INSTALL_DIR}/include)
add_dependencies(SPIRV-Headers spirv_headers_project)

set(SPIRV_HEADERS_INCLUDE_DIR ${SPIRV_HEADERS_INSTALL_DIR}/include CACHE INTERNAL "SPIRV-Headers include directory")
