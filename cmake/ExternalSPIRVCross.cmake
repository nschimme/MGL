# SPIRV-Cross
ExternalProject_Add(spirv_cross_project
    GIT_REPOSITORY https://github.com/KhronosGroup/SPIRV-Cross.git
    GIT_TAG main # Or a specific commit/tag
    SOURCE_DIR ${CMAKE_BINARY_DIR}/external/spirv_cross
    BINARY_DIR ${CMAKE_BINARY_DIR}/external/spirv_cross-build
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/external/spirv_cross-install
        -DSPIRV_CROSS_ENABLE_TESTS=OFF
        -DSPIRV_CROSS_ENABLE_C_API=ON
        -DSPIRV_CROSS_ENABLE_CPP_API=ON
        -DSPIRV_CROSS_ENABLE_MSL_API=ON
        -DSPIRV_CROSS_ENABLE_GLSL_API=ON
        -DSPIRV_CROSS_ENABLE_HLSL_API=ON
        -DSPIRV_CROSS_ENABLE_REFLECT_API=ON
        -DSPIRV_CROSS_SKIP_INSTALL=OFF # Ensure install step is run
    BUILD_COMMAND $(MAKE) # Use $(MAKE) for parallel builds if supported
    INSTALL_COMMAND $(MAKE) install
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)

# Create imported targets for SPIRV-Cross libraries
# The actual library names might differ based on SPIRV-Cross build configuration
# Add more libraries if needed (e.g., spirv-cross-msl, spirv-cross-hlsl)
set(SPIRV_CROSS_INSTALL_DIR ${CMAKE_BINARY_DIR}/external/spirv_cross-install)
add_library(SPIRV-Cross::spirv-cross-c STATIC IMPORTED GLOBAL)
set_property(TARGET SPIRV-Cross::spirv-cross-c PROPERTY IMPORTED_LOCATION ${SPIRV_CROSS_INSTALL_DIR}/lib/libspirv-cross-c.a)
add_dependencies(SPIRV-Cross::spirv-cross-c spirv_cross_project)

add_library(SPIRV-Cross::spirv-cross-cpp STATIC IMPORTED GLOBAL)
set_property(TARGET SPIRV-Cross::spirv-cross-cpp PROPERTY IMPORTED_LOCATION ${SPIRV_CROSS_INSTALL_DIR}/lib/libspirv-cross-cpp.a)
add_dependencies(SPIRV-Cross::spirv-cross-cpp spirv_cross_project)

add_library(SPIRV-Cross::spirv-cross-core STATIC IMPORTED GLOBAL)
set_property(TARGET SPIRV-Cross::spirv-cross-core PROPERTY IMPORTED_LOCATION ${SPIRV_CROSS_INSTALL_DIR}/lib/libspirv-cross-core.a)
add_dependencies(SPIRV-Cross::spirv-cross-core spirv_cross_project)

add_library(SPIRV-Cross::spirv-cross-glsl STATIC IMPORTED GLOBAL)
set_property(TARGET SPIRV-Cross::spirv-cross-glsl PROPERTY IMPORTED_LOCATION ${SPIRV_CROSS_INSTALL_DIR}/lib/libspirv-cross-glsl.a)
add_dependencies(SPIRV-Cross::spirv-cross-glsl spirv_cross_project)

add_library(SPIRV-Cross::spirv-cross-msl STATIC IMPORTED GLOBAL)
set_property(TARGET SPIRV-Cross::spirv-cross-msl PROPERTY IMPORTED_LOCATION ${SPIRV_CROSS_INSTALL_DIR}/lib/libspirv-cross-msl.a)
add_dependencies(SPIRV-Cross::spirv-cross-msl spirv_cross_project)

add_library(SPIRV-Cross::spirv-cross-hlsl STATIC IMPORTED GLOBAL)
set_property(TARGET SPIRV-Cross::spirv-cross-hlsl PROPERTY IMPORTED_LOCATION ${SPIRV_CROSS_INSTALL_DIR}/lib/libspirv-cross-hlsl.a)
add_dependencies(SPIRV-Cross::spirv-cross-hlsl spirv_cross_project)

add_library(SPIRV-Cross::spirv-cross-reflect STATIC IMPORTED GLOBAL)
set_property(TARGET SPIRV-Cross::spirv-cross-reflect PROPERTY IMPORTED_LOCATION ${SPIRV_CROSS_INSTALL_DIR}/lib/libspirv-cross-reflect.a)
add_dependencies(SPIRV-Cross::spirv-cross-reflect spirv_cross_project)


# Interface target for include directories
# Ensure the include directory exists at configure time to prevent errors when the interface target is defined.
file(MAKE_DIRECTORY ${SPIRV_CROSS_INSTALL_DIR}/include)
add_library(SPIRV-Cross INTERFACE IMPORTED GLOBAL)
target_include_directories(SPIRV-Cross INTERFACE ${SPIRV_CROSS_INSTALL_DIR}/include)
add_dependencies(SPIRV-Cross spirv_cross_project)

# Make SPIRV-Cross install directory available
set(SPIRV_CROSS_INCLUDE_DIR ${SPIRV_CROSS_INSTALL_DIR}/include CACHE INTERNAL "SPIRV-Cross include directory")
set(SPIRV_CROSS_LIBRARY_DIR ${SPIRV_CROSS_INSTALL_DIR}/lib CACHE INTERNAL "SPIRV-Cross library directory")

# Add a custom target to easily access the include directory
add_custom_target(PrintSPIRVCrossPaths
    COMMAND ${CMAKE_COMMAND} -E echo "SPIRV-Cross include: ${SPIRV_CROSS_INCLUDE_DIR}"
    COMMAND ${CMAKE_COMMAND} -E echo "SPIRV-Cross libraries: ${SPIRV_CROSS_LIBRARY_DIR}"
)
add_dependencies(PrintSPIRVCrossPaths spirv_cross_project)
