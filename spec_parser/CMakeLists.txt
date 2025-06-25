# spec_parser CMakeLists.txt

# Gather source files
file(GLOB SPEC_PARSER_SOURCES "*.c") # Assuming .c files, adjust if there are .h files that are part of the compilation unit directly

# Add executable for spec_parser
add_executable(spec_parser ${SPEC_PARSER_SOURCES})

# spec_parser might also use ezxml or other libraries.
# From the file list, it's not immediately clear, but if it does, link them similarly to enum_parser.
# For example, if it uses ezxml:
# target_include_directories(spec_parser PRIVATE ${EZXML_INCLUDE_DIR})
# target_link_libraries(spec_parser PRIVATE Ezxml::ezxml)
# add_dependencies(spec_parser ezxml_project)

# If spec_parser generates code that MGL uses, you might need custom commands.
# For now, just building the executable.

# Installation (optional)
install(TARGETS spec_parser DESTINATION bin)

# It seems spec_parser/mgl_funcs.c and spec_parser/mgl.h are related to MGL.
# If spec_parser generates these or uses them as input/output, further configuration is needed.
# The Makefile doesn't show spec_parser being run as part of the MGL build directly,
# but it's a common pattern for such tools.
# For now, we are just compiling the tool itself.
# If mgl.h is generated, then MGL library would depend on a custom command running spec_parser.

# Based on `spec_parser/spec_parser.c` and `spec_parser/mgl_funcs.c` it seems like `spec_parser`
# is intended to parse some specification (likely related to OpenGL, given the project)
# and generate C code, possibly `mgl_funcs.c` or parts of it.
# The `mgl.h` in this directory might be an input or a shared header.

# For now, the CMake builds the `spec_parser` executable.
# If it's a code generator:
# 1. Identify inputs (e.g., XML spec file from OpenGL-Registry)
# 2. Identify outputs (e.g., generated .c or .h files)
# 3. Add a custom command to run spec_parser with appropriate arguments.
#    add_custom_command(
#        OUTPUT path/to/generated_file.c
#        COMMAND spec_parser <args> path/to/input_spec.xml path/to/generated_file.c
#        DEPENDS spec_parser path/to/input_spec.xml
#        COMMENT "Generating sources with spec_parser"
#    )
# 4. Add the generated source file to the MGL library's sources.
#    target_sources(MGL PRIVATE path/to/generated_file.c)

# This level of integration requires more info on how spec_parser is used.
# The Makefile doesn't explicitly run it. It might be a tool run manually by developers.
# The current scope is to make it buildable with CMake.
# Check if it needs ezxml, it has ezxml.h and ezxml.c in enum_parser, maybe copied or linked.
# The `enum_parser` directory has its own `ezxml.c` and `ezxml.h`.
# The `spec_parser` does not, so if it needs ezxml, it would need to link to the one
# we build with `ExternalProject_Add` or the one from `enum_parser` if that's intended.
# Let's assume for now it does *not* directly use ezxml, but if build errors show missing symbols,
# we'll add the dependency.

# The Makefile has EXT_DIRS including ./external/OpenGL-Registry and ./external/ezxml
# OpenGL-Registry is likely input for spec_parser.
# ezxml is used by enum_parser.

# Let's add OpenGL-Registry as an ExternalProject if spec_parser needs it at build time.
# For now, assuming it's a manually run tool or its inputs are pre-committed.

# Add dependency on ezxml_project if spec_parser uses ezxml
# Based on a quick look at spec_parser.c, it includes "ezxml.h".
# It's not clear if it expects a local copy or the one from enum_parser or system.
# Let's assume it should use the common `ezxml` we're building.
find_package(Ezxml REQUIRED) # Ensure our ExternalEzxml.cmake has run and set up Ezxml::ezxml
target_link_libraries(spec_parser PRIVATE Ezxml::ezxml)
add_dependencies(spec_parser ezxml_project) # Explicit dependency on the project itself

# Also, spec_parser.c includes "mgl_hacks.h", "gl_core_3_3.h", "gl_es_2_0.h", "gl_es_3_0.h", "gl_es_3_1.h", "gl_es_3_2.h"
# These are not standard headers. They might be generated or come from OpenGL-Registry.
# The OpenGL-Registry is in ./external/OpenGL-Registry
# We need to make sure these headers are available.
# The Makefile clones OpenGL-Registry. Let's add it as an external project for its headers.

# We need to define OpenGL_Registry_project similar to other external projects.
# This should be in the root CMakeLists.txt or a dedicated cmake/ExternalOpenGLRegistry.cmake

# For now, assuming these headers are either:
# 1. Pre-existing in the spec_parser directory (they are not, based on ls)
# 2. Expected to be found in a global include path (unlikely for project-specific headers)
# 3. Are supposed to be generated or copied from external/OpenGL-Registry/api/GL/
# Let's assume for now they are from external/OpenGL-Registry/api/GL/ (or similar path)

# This means spec_parser needs an include path to where OpenGL-Registry is downloaded.
# Let's add an INTERFACE target for OpenGL-Registry's includes.

# In root CMakeLists.txt (or a new cmake/ExternalOpenGLRegistry.cmake):
# ExternalProject_Add(opengl_registry_project
# GIT_REPOSITORY https://github.com/KhronosGroup/OpenGL-Registry.git
# SOURCE_DIR ${CMAKE_BINARY_DIR}/external/OpenGL-Registry
# CONFIGURE_COMMAND ""
# BUILD_COMMAND ""
# INSTALL_COMMAND "" # It's just a source of headers/specs
# )
# add_library(OpenGL-Registry INTERFACE)
# target_include_directories(OpenGL-Registry INTERFACE ${CMAKE_BINARY_DIR}/external/OpenGL-Registry/api) # Adjust path as needed
# add_dependencies(OpenGL-Registry opengl_registry_project)

# Then, here:
# target_link_libraries(spec_parser PRIVATE OpenGL-Registry)
# add_dependencies(spec_parser opengl_registry_project)

# This dependency should be added to the root CMakeLists.txt first.
# For now, this CMakeLists.txt for spec_parser will be incomplete regarding these headers.
# I will add OpenGL-Registry to the external dependencies list.

# Given the current plan, I will create a placeholder for OpenGL-Registry dependency
# and will add the actual ExternalProject_Add in the root CMakeLists.txt modification step for external deps
# or as a new step if needed.

if(TARGET OpenGL-Registry)
    target_link_libraries(spec_parser PRIVATE OpenGL-Registry)
    add_dependencies(spec_parser opengl_registry_project) # Assuming opengl_registry_project is the ExternalProject name
else()
    message(WARNING "OpenGL-Registry target not found. spec_parser might fail to build if it needs headers from it.")
endif()

# Also, spec_parser.c includes "mgl.h". This is from the MGL library's include directory.
target_include_directories(spec_parser PRIVATE
    ${CMAKE_SOURCE_DIR}/MGL/include # Path to MGL's public headers
)
# It does not need to link MGL library, just access its headers.
# This creates a slight ordering issue if mgl.h is generated by something else, but mgl.h is a source file.

# The file mgl_funcs.c in spec_parser directory seems to be an output of spec_parser, not a source.
# The Makefile rule for mgl_objs includes MGL/src/*.c. If mgl_funcs.c is generated into MGL/src,
# then MGL library build would depend on spec_parser running.
# The spec_parser.c seems to write to files like "mgl_funcs_ext.c", "mgl_funcs_dep.c", etc.
# This definitely looks like a code generator.

# For now, this CMakeLists.txt only *builds* the spec_parser executable.
# Integrating its execution to generate source files for MGL is a more complex step
# that would involve add_custom_command and add_custom_target.
# This is deferred until we confirm how it's meant to be integrated.

# The Makefile does not show `spec_parser` being run to generate `mgl_funcs.c`.
# `MGL/src/mgl_funcs_to_be_implemented.c` exists, which might be a template or placeholder.
# It's possible `spec_parser` is a utility for developers and not part of the automated build.
# We will proceed with just building the executable.
# If `mgl_funcs.c` (or similar) is indeed generated and used by MGL, the MGL/CMakeLists.txt
# would need to be updated to depend on a custom command that runs `spec_parser`.

# Final check on includes for spec_parser.c:
# "stdio.h", "stdlib.h", "string.h", "ezxml.h" -> From Ezxml::ezxml
# "mgl_hacks.h" -> Needs to be found (OpenGL-Registry?)
# "gl_core_3_3.h", etc. -> Needs to be found (OpenGL-Registry?)
# "mgl.h" -> From MGL/include

# Let's assume for now that "mgl_hacks.h" and the "gl_*.h" files are located alongside spec_parser.c or in a subdirectory.
# A `ls spec_parser/` would clarify this. If they are missing, the build will fail, and we'll address it.
# The `ls` output at the beginning shows:
# spec_parser/
# spec_parser/mgl.h
# spec_parser/mgl_funcs.c
# spec_parser/spec_parser.c
# It does *not* show mgl_hacks.h or gl_core_*.h. These must come from `external/OpenGL-Registry/api`
# So, the OpenGL-Registry dependency is crucial.

# I will add ExternalOpenGLRegistry.cmake now and include it in the root CMakeLists.txt
# This deviates slightly from doing one step at a time, but spec_parser depends on it.
# This should be part of "Add CMake targets for external dependencies" step, which is already "complete".
# I will make a note to potentially revisit that step or handle it here.
# For now, I'll proceed with writing spec_parser/CMakeLists.txt assuming OpenGL-Registry target will exist.

# To make this self-contained for now and testable for spec_parser alone, one might temporarily
# comment out the OpenGL-Registry parts if that external project isn't set up yet.
# However, the goal is a fully working build.
# I will add the OpenGL-Registry part to the `cmake/` directory and update root `CMakeLists.txt`
# as part of this current step for `spec_parser`, as it's a direct dependency for it to compile.

# First, create `cmake/ExternalOpenGLRegistry.cmake`
# Then, update root `CMakeLists.txt` to include it.
# Then, this `spec_parser/CMakeLists.txt` can use the `OpenGL-Registry` target.
# This is a slight re-ordering of planned work but necessary for correctness.
