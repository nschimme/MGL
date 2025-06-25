# glslang
ExternalProject_Add(glslang_project
    GIT_REPOSITORY https://github.com/KhronosGroup/glslang.git
    GIT_TAG main # Or a specific tag/commit
    RECURSE_SUBMODULES TRUE # Downloads SPIRV-Tools, etc. but we use our own
    SOURCE_DIR ${CMAKE_BINARY_DIR}/external/glslang
    BINARY_DIR ${CMAKE_BINARY_DIR}/external/glslang-build
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/external/glslang-install
        -DBUILD_SHARED_LIBS=OFF # Build static libs
        -DENABLE_GLSLANG_BINARIES=OFF # Don't build glslangValidator, etc.
        -DENABLE_HLSL=ON
        -DENABLE_OPT=ON
        # Ensure it uses the SPIRV-Tools we are building
        # This might require glslang to have specific CMake options to point to an external SPIRV-Tools build
        # For now, let it use its own, or assume it can find the one we built if installed system-wide by previous step (not ideal)
        # A more robust solution would be to patch glslang's CMake or ensure it has options to find our SPIRV-Tools
    BUILD_COMMAND $(MAKE)
    INSTALL_COMMAND $(MAKE) install
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)

set(GLSLANG_INSTALL_DIR ${CMAKE_BINARY_DIR}/external/glslang-install)

# Create imported targets for glslang libraries
add_library(Glslang::glslang STATIC IMPORTED GLOBAL)
set_property(TARGET Glslang::glslang PROPERTY IMPORTED_LOCATION ${GLSLANG_INSTALL_DIR}/lib/libglslang.a)
add_dependencies(Glslang::glslang glslang_project)

add_library(Glslang::OSDependent STATIC IMPORTED GLOBAL)
set_property(TARGET Glslang::OSDependent PROPERTY IMPORTED_LOCATION ${GLSLANG_INSTALL_DIR}/lib/libOSDependent.a)
add_dependencies(Glslang::OSDependent glslang_project)

add_library(Glslang::OGLCompiler STATIC IMPORTED GLOBAL)
set_property(TARGET Glslang::OGLCompiler PROPERTY IMPORTED_LOCATION ${GLSLANG_INSTALL_DIR}/lib/libOGLCompiler.a)
add_dependencies(Glslang::OGLCompiler glslang_project)

add_library(Glslang::SPIRV STATIC IMPORTED GLOBAL)
set_property(TARGET Glslang::SPIRV PROPERTY IMPORTED_LOCATION ${GLSLANG_INSTALL_DIR}/lib/libSPIRV.a)
add_dependencies(Glslang::SPIRV glslang_project)

add_library(Glslang::MachineIndependent STATIC IMPORTED GLOBAL)
set_property(TARGET Glslang::MachineIndependent PROPERTY IMPORTED_LOCATION ${GLSLANG_INSTALL_DIR}/lib/libMachineIndependent.a)
add_dependencies(Glslang::MachineIndependent glslang_project)

add_library(Glslang::GenericCodeGen STATIC IMPORTED GLOBAL) # Might not exist as separate lib, often part of MachineIndependent
set_property(TARGET Glslang::GenericCodeGen PROPERTY IMPORTED_LOCATION ${GLSLANG_INSTALL_DIR}/lib/libGenericCodeGen.a)
add_dependencies(Glslang::GenericCodeGen glslang_project)

# For glslang-default-resource-limits
# This library might be named differently or part of another library depending on glslang version and build options.
# Check the actual built library names in glslang-install/lib.
# It might be libglslang-default-resource-limits.a or integrated into libglslang.a
# If it's separate, create an imported target for it.
# Example:
# add_library(Glslang::glslang-default-resource-limits STATIC IMPORTED GLOBAL)
# set_property(TARGET Glslang::glslang-default-resource-limits PROPERTY IMPORTED_LOCATION ${GLSLANG_INSTALL_DIR}/lib/libglslang-default-resource-limits.a)
# add_dependencies(Glslang::glslang-default-resource-limits glslang_project)


# Interface target for include directories
add_library(Glslang INTERFACE IMPORTED GLOBAL)
target_include_directories(Glslang INTERFACE ${GLSLANG_INSTALL_DIR}/include)
add_dependencies(Glslang glslang_project)

set(GLSLANG_INCLUDE_DIR ${GLSLANG_INSTALL_DIR}/include CACHE INTERNAL "glslang include directory")
set(GLSLANG_LIBRARY_DIR ${GLSLANG_INSTALL_DIR}/lib CACHE INTERNAL "glslang library directory")
