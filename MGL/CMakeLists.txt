# MGL Library CMakeLists.txt

if(NOT APPLE)
    message(STATUS "Skipping MGL library build on non-Apple platform.")
    return()
endif()

set(MGL_VERSION_MAJOR 1)
set(MGL_VERSION_MINOR 0)
set(MGL_VERSION_PATCH 0)
set(MGL_VERSION_STRING "${MGL_VERSION_MAJOR}.${MGL_VERSION_MINOR}.${MGL_VERSION_PATCH}")

# Gather source files
# C sources
file(GLOB MGL_C_SOURCES
    "src/*.c"
    "spirv_cross_c.cpp" # This is a .cpp file but seems to be part of the C API bindings for SPIRV-Cross
)

# Objective-C sources
file(GLOB MGL_OBJC_SOURCES
    "src/*.m"
)

set(MGL_SOURCES ${MGL_C_SOURCES} ${MGL_OBJC_SOURCES})

# Include directories for MGL
include_directories(
    "${CMAKE_CURRENT_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/include/GL" # For glcorearb.h
    # Add include directories from external dependencies
    # These are typically handled by target_link_libraries with INTERFACE properties
    # but can be added explicitly if needed for some build setups or older CMake.
    # However, modern CMake prefers using targets.
)

# Add MGL library target
add_library(MGL SHARED ${MGL_SOURCES}) # Or STATIC if preferred, Makefile builds dylib (SHARED)

# Set MGL library properties
set_target_properties(MGL PROPERTIES
    VERSION ${MGL_VERSION_STRING}
    SOVERSION ${MGL_VERSION_MAJOR}
    PUBLIC_HEADER "include/mgl.h;include/MGLContext.h;include/MGLRenderer.h" # Add other public headers
    # For macOS, specify framework-like properties if needed
    FRAMEWORK TRUE # This will create MGL.framework bundle if that's the goal
    MACOSX_FRAMEWORK_IDENTIFIER org.mgl.MGL
    # If not building as a framework, but just a dylib, remove FRAMEWORK TRUE
    # and ensure install paths are set correctly.
    # For dylib, ensure install name is set correctly for rpath handling if needed.
    # INSTALL_NAME_DIR "@rpath" # Or specific path
)


# Link MGL against its dependencies
target_link_libraries(MGL
    PUBLIC
        # External Libraries (using the INTERFACE or IMPORTED targets defined in cmake/External*.cmake)
        GLM # GLM::glm is the actual target, GLM is an interface wrapper
        SPIRV-Cross # Interface target for includes
        SPIRV-Cross::spirv-cross-c
        SPIRV-Cross::spirv-cross-cpp
        SPIRV-Cross::spirv-cross-core
        SPIRV-Cross::spirv-cross-glsl
        SPIRV-Cross::spirv-cross-msl
        SPIRV-Cross::spirv-cross-hlsl
        SPIRV-Cross::spirv-cross-reflect
        SPIRV-Tools # Interface target for includes
        SPIRV-Tools::SPIRV-Tools
        SPIRV-Tools::SPIRV-Tools-opt
        # Add other SPIRV-Tools components if needed (link, reduce, lint)
        SPIRV-Headers # Interface target for includes
        Glslang # Interface target for includes
        Glslang::glslang
        Glslang::OSDependent
        Glslang::OGLCompiler
        Glslang::SPIRV
        Glslang::MachineIndependent
        # Glslang::GenericCodeGen # If it exists as a separate library
        # Glslang::glslang-default-resource-limits # If it exists
        GLFW::glfw # Actual imported target for GLFW library
    PRIVATE
        # System Frameworks (macOS) - these are already in a global variable SYSTEM_FRAMEWORKS
        ${SYSTEM_FRAMEWORKS}
)

# Add specific compiler flags from Makefile for MGL if they aren't global
# CFLAGS += -DENABLE_OPT=0 -DSPIRV_CROSS_C_API_MSL=1 -DSPIRV_CROSS_C_API_GLSL=1 -DSPIRV_CROSS_C_API_CPP=1 -DSPIRV_CROSS_C_API_REFLECT=1
target_compile_definitions(MGL PRIVATE
    ENABLE_OPT=0
    SPIRV_CROSS_C_API_MSL=1
    SPIRV_CROSS_C_API_GLSL=1
    SPIRV_CROSS_C_API_CPP=1
    SPIRV_CROSS_C_API_REFLECT=1
)

# Installation (optional, but good practice)
install(TARGETS MGL
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    FRAMEWORK DESTINATION Frameworks # If FRAMEWORK TRUE is set
    PUBLIC_HEADER DESTINATION include/MGL # Adjust path as needed
)

# Create a symbolic link for libmgl.dylib in the build directory's root for compatibility with Makefile expectations if needed
# This is more of a convenience for local testing if other scripts expect it there.
# add_custom_command(TARGET MGL POST_BUILD
# COMMAND ${CMAKE_COMMAND} -E create_symlink $<TARGET_FILE_DIR:MGL>/$<TARGET_FILE_NAME:MGL> ${CMAKE_BINARY_DIR}/libmgl.dylib
# COMMENT "Creating symlink libmgl.dylib in build root"
# )

# Ensure external projects are built before MGL
add_dependencies(MGL
    spirv_cross_project
    spirv_tools_project
    spirv_headers_project
    glslang_project
    glfw_project
    # ezxml_project # Not directly linked by MGL library itself, but maybe by tests or apps
    # glm_project # Dependency handled by GLM::glm target
)

# If MGL/spirv_cross_c.cpp needs includes from SPIRV-Cross source (not just install)
# This is less ideal than using the installed headers via SPIRV-Cross INTERFACE target
# target_include_directories(MGL PRIVATE ${CMAKE_BINARY_DIR}/external/spirv_cross/include)

# If Objective-C sources need specific flags (e.g. ARC)
set_source_files_properties(${MGL_OBJC_SOURCES}
    PROPERTIES COMPILE_FLAGS "-fobjc-arc -fmodules"
)

# For MGL/include/glm/* headers, these are part of the MGL library's own include set
# but GLM itself is an external dependency. We use the GLM::glm target for the actual GLM library.
# The headers in MGL/include/glm seem to be a copy or submodule.
# If they are intended to be *the* GLM used by MGL, then we should prioritize them.
# However, the Makefile uses pkg-config for glm or a submodule, suggesting external.
# The current setup uses the external GLM project.
# If MGL/include/glm is *the* source, then remove GLM from target_link_libraries and add:
# target_include_directories(MGL PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/include/glm")
# For now, assuming external GLM is primary, and MGL/include/glm might be for specific extensions or older code.
# The `glm` subdirectory in `MGL/include` looks like a full copy of GLM.
# This is redundant if we are building GLM externally.
# Let's assume the external GLM is the one to use for now.
# The `MGL/include/glm/CMakeLists.txt` might be for building this embedded copy.
# For now, we will ignore `MGL/include/glm/CMakeLists.txt`.

message(STATUS "MGL Sources: ${MGL_SOURCES}")
