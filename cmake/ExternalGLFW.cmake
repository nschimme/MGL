# GLFW
ExternalProject_Add(glfw_project
    GIT_REPOSITORY https://github.com/glfw/glfw.git
    GIT_TAG latest # Or a specific version tag e.g. 3.3.8
    SOURCE_DIR ${CMAKE_BINARY_DIR}/external/glfw
    BINARY_DIR ${CMAKE_BINARY_DIR}/external/glfw-build
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/external/glfw-install
        -DGLFW_BUILD_EXAMPLES=OFF
        -DGLFW_BUILD_TESTS=OFF
        -DGLFW_BUILD_DOCS=OFF
        -DBUILD_SHARED_LIBS=OFF # Build static lib
    BUILD_COMMAND $(MAKE)
    INSTALL_COMMAND $(MAKE) install
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)

set(GLFW_INSTALL_DIR ${CMAKE_BINARY_DIR}/external/glfw-install)

# Create imported target for GLFW library
add_library(GLFW::glfw STATIC IMPORTED GLOBAL) # Changed from SHARED to STATIC
set_property(TARGET GLFW::glfw PROPERTY IMPORTED_LOCATION ${GLFW_INSTALL_DIR}/lib/libglfw3.a) # libglfw3.a for static
add_dependencies(GLFW::glfw glfw_project)

# Interface target for include directories
add_library(GLFW INTERFACE IMPORTED GLOBAL)
target_include_directories(GLFW INTERFACE ${GLFW_INSTALL_DIR}/include)
add_dependencies(GLFW glfw_project)

set(GLFW_INCLUDE_DIR ${GLFW_INSTALL_DIR}/include CACHE INTERNAL "GLFW include directory")
set(GLFW_LIBRARY_DIR ${GLFW_INSTALL_DIR}/lib CACHE INTERNAL "GLFW library directory")
