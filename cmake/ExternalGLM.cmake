# GLM
# Option 1: Try to find_package (if GLM is installed system-wide or via another CMake package)
find_package(glm QUIET)

if(glm_FOUND)
    message(STATUS "Found GLM version ${glm_VERSION}")
    add_library(GLM::glm ALIAS glm::glm) # Ensure our target name GLM::glm exists
    set(GLM_INCLUDE_DIR ${glm_INCLUDE_DIRS} CACHE INTERNAL "GLM include directory from find_package")
else()
    message(STATUS "GLM not found via find_package. Building from source.")
    ExternalProject_Add(glm_project
        GIT_REPOSITORY https://github.com/g-truc/glm.git
        GIT_TAG 0.9.9.8 # Specify a version
        SOURCE_DIR ${CMAKE_BINARY_DIR}/external/glm
        BINARY_DIR ${CMAKE_BINARY_DIR}/external/glm-build
        CMAKE_ARGS
            -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/external/glm-install
            -DGLM_TEST_ENABLE=OFF
        BUILD_COMMAND $(MAKE) # GLM can be header-only but can also be built/installed
        INSTALL_COMMAND $(MAKE) install
        LOG_DOWNLOAD ON
        LOG_CONFIGURE ON
        LOG_BUILD ON
        LOG_INSTALL ON
    )

    set(GLM_INSTALL_DIR ${CMAKE_BINARY_DIR}/external/glm-install)

    # GLM is often header-only, but we create an INTERFACE library for consistency.
    # If GLM is built as a library, you'd link to it.
    # For header-only, you primarily need the include directory.
    add_library(GLM::glm INTERFACE IMPORTED GLOBAL) # Use INTERFACE for header-only
    # The include directory depends on GLM's structure and install process.
    # Typically it's <install_prefix>/include or <install_prefix>/include/glm
    target_include_directories(GLM::glm INTERFACE ${GLM_INSTALL_DIR}/include)
    add_dependencies(GLM::glm glm_project)

    set(GLM_INCLUDE_DIR ${GLM_INSTALL_DIR}/include CACHE INTERNAL "GLM include directory from source build")
endif()

# Interface library for GLM (either found or built)
add_library(GLM INTERFACE)
target_link_libraries(GLM INTERFACE GLM::glm)
# This ensures that targets linking against GLM will get the include directories from GLM::glm.

# For MGL code that might be doing #include <glm/glm.hpp>
# Ensure GLM_INCLUDE_DIR is available for direct use if needed, though target_link_libraries is preferred.
# The actual include path might be ${GLM_INSTALL_DIR}/include or just ${GLM_INSTALL_DIR} if glm headers are directly in there.
# Adjust if necessary based on glm's install layout.
# This line is mostly for informational purposes or for legacy include styles.
include_directories(SYSTEM ${GLM_INCLUDE_DIR})
