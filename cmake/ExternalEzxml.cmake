# Ezxml
ExternalProject_Add(ezxml_project
    GIT_REPOSITORY https://github.com/lxfontes/ezxml.git
    GIT_TAG master # Or a specific commit/tag
    SOURCE_DIR ${CMAKE_BINARY_DIR}/external/ezxml
    BINARY_DIR ${CMAKE_BINARY_DIR}/external/ezxml-build # Not a CMake project, so build dir might not be used in typical way
    CONFIGURE_COMMAND "" # No CMake/configure script
    BUILD_COMMAND ${CMAKE_C_COMPILER} ${CMAKE_C_FLAGS} -c <SOURCE_DIR>/ezxml.c -o <BINARY_DIR>/ezxml.o
    INSTALL_COMMAND ${CMAKE_AR} rcs <BINARY_DIR>/libezxml.a <BINARY_DIR>/ezxml.o && \
                    ${CMAKE_COMMAND} -E copy <BINARY_DIR>/libezxml.a ${CMAKE_BINARY_DIR}/external/ezxml-install/lib/libezxml.a && \
                    ${CMAKE_COMMAND} -E copy <SOURCE_DIR>/ezxml.h ${CMAKE_BINARY_DIR}/external/ezxml-install/include/ezxml.h
    # Create install directory for headers and library
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/external/ezxml-install/lib
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/external/ezxml-install/include
    LOG_DOWNLOAD ON
    LOG_BUILD ON
    LOG_INSTALL ON
)

set(EZXML_INSTALL_DIR ${CMAKE_BINARY_DIR}/external/ezxml-install)

# Create imported target for ezxml library
add_library(Ezxml::ezxml STATIC IMPORTED GLOBAL)
set_property(TARGET Ezxml::ezxml PROPERTY IMPORTED_LOCATION ${EZXML_INSTALL_DIR}/lib/libezxml.a)
add_dependencies(Ezxml::ezxml ezxml_project)

# Interface target for include directories
add_library(Ezxml INTERFACE IMPORTED GLOBAL)
target_include_directories(Ezxml INTERFACE ${EZXML_INSTALL_DIR}/include)
add_dependencies(Ezxml ezxml_project)

set(EZXML_INCLUDE_DIR ${EZXML_INSTALL_DIR}/include CACHE INTERNAL "Ezxml include directory")
set(EZXML_LIBRARY_DIR ${EZXML_INSTALL_DIR}/lib CACHE INTERNAL "Ezxml library directory")
