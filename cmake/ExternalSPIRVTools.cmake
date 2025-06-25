# SPIRV-Tools
ExternalProject_Add(spirv_tools_project
    GIT_REPOSITORY https://github.com/KhronosGroup/SPIRV-Tools.git
    GIT_TAG main # Or a specific commit/tag
    RECURSE_SUBMODULES TRUE # SPIRV-Headers is a submodule
    SOURCE_DIR ${CMAKE_BINARY_DIR}/external/spirv_tools
    BINARY_DIR ${CMAKE_BINARY_DIR}/external/spirv_tools-build
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/external/spirv_tools-install
        -DSPIRV_TOOLS_BUILD_STATIC=ON
        -DSPIRV_TOOLS_BUILD_SHARED=OFF # Build static libs
        -DSPIRV_SKIP_TESTS=ON
        -DSPIRV_WERROR=OFF
        # SPIRV-Headers is a submodule, so we tell SPIRV-Tools to use our build of it
        -DSPIRV_HEADERS_LOCAL_PATH=${CMAKE_BINARY_DIR}/external/spirv_headers
        -DSPIRV_HEADERS_SKIP_INSTALL=ON # We handle SPIRV-Headers installation separately
    BUILD_COMMAND $(MAKE)
    INSTALL_COMMAND $(MAKE) install
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)

set(SPIRV_TOOLS_INSTALL_DIR ${CMAKE_BINARY_DIR}/external/spirv_tools-install)

# Create imported targets for SPIRV-Tools libraries
add_library(SPIRV-Tools::SPIRV-Tools STATIC IMPORTED GLOBAL)
set_property(TARGET SPIRV-Tools::SPIRV-Tools PROPERTY IMPORTED_LOCATION ${SPIRV_TOOLS_INSTALL_DIR}/lib/libSPIRV-Tools.a)
add_dependencies(SPIRV-Tools::SPIRV-Tools spirv_tools_project)

add_library(SPIRV-Tools::SPIRV-Tools-opt STATIC IMPORTED GLOBAL)
set_property(TARGET SPIRV-Tools::SPIRV-Tools-opt PROPERTY IMPORTED_LOCATION ${SPIRV_TOOLS_INSTALL_DIR}/lib/libSPIRV-Tools-opt.a)
add_dependencies(SPIRV-Tools::SPIRV-Tools-opt spirv_tools_project)

add_library(SPIRV-Tools::SPIRV-Tools-link STATIC IMPORTED GLOBAL)
set_property(TARGET SPIRV-Tools::SPIRV-Tools-link PROPERTY IMPORTED_LOCATION ${SPIRV_TOOLS_INSTALL_DIR}/lib/libSPIRV-Tools-link.a)
add_dependencies(SPIRV-Tools::SPIRV-Tools-link spirv_tools_project)

add_library(SPIRV-Tools::SPIRV-Tools-reduce STATIC IMPORTED GLOBAL)
set_property(TARGET SPIRV-Tools::SPIRV-Tools-reduce PROPERTY IMPORTED_LOCATION ${SPIRV_TOOLS_INSTALL_DIR}/lib/libSPIRV-Tools-reduce.a)
add_dependencies(SPIRV-Tools::SPIRV-Tools-reduce spirv_tools_project)

add_library(SPIRV-Tools::SPIRV-Tools-lint STATIC IMPORTED GLOBAL)
set_property(TARGET SPIRV-Tools::SPIRV-Tools-lint PROPERTY IMPORTED_LOCATION ${SPIRV_TOOLS_INSTALL_DIR}/lib/libSPIRV-Tools-lint.a)
add_dependencies(SPIRV-Tools::SPIRV-Tools-lint spirv_tools_project)

# Interface target for include directories
add_library(SPIRV-Tools INTERFACE IMPORTED GLOBAL)
target_include_directories(SPIRV-Tools INTERFACE ${SPIRV_TOOLS_INSTALL_DIR}/include)
add_dependencies(SPIRV-Tools spirv_tools_project)

set(SPIRV_TOOLS_INCLUDE_DIR ${SPIRV_TOOLS_INSTALL_DIR}/include CACHE INTERNAL "SPIRV-Tools include directory")
set(SPIRV_TOOLS_LIBRARY_DIR ${SPIRV_TOOLS_INSTALL_DIR}/lib CACHE INTERNAL "SPIRV-Tools library directory")
