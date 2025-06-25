# Ezxml
ExternalProject_Add(ezxml_project
    GIT_REPOSITORY https://github.com/lxfontes/ezxml.git
    GIT_TAG master # Or a specific commit/tag
    SOURCE_DIR ${CMAKE_BINARY_DIR}/external/ezxml
    BINARY_DIR ${CMAKE_BINARY_DIR}/external/ezxml-build # Not a CMake project, so build dir might not be used in typical way
    CONFIGURE_COMMAND "" # No CMake/configure script
    # Step 1: Compile ezxml.c to an object file
    BUILD_COMMAND ${CMAKE_C_COMPILER} ${CMAKE_C_FLAGS} -I<SOURCE_DIR> -c <SOURCE_DIR>/ezxml.c -o <BINARY_DIR>/ezxml.o
    # Step 2: Create the static library
    COMMAND ${CMAKE_AR} rcs <BINARY_DIR>/libezxml.a <BINARY_DIR>/ezxml.o
    # Step 3: Create installation directories
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/external/ezxml-install/lib
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/external/ezxml-install/include
    # Step 4: Install the library
    COMMAND ${CMAKE_COMMAND} -E copy <BINARY_DIR>/libezxml.a ${CMAKE_BINARY_DIR}/external/ezxml-install/lib/libezxml.a
    # Step 5: Install the header
    INSTALL_COMMAND ${CMAKE_COMMAND} -E copy <SOURCE_DIR>/ezxml.h ${CMAKE_BINARY_DIR}/external/ezxml-install/include/ezxml.h
    LOG_DOWNLOAD ON
    LOG_BUILD ON
    LOG_INSTALL ON
)

set(EZXML_INSTALL_DIR ${CMAKE_BINARY_DIR}/external/ezxml-install CACHE PATH "ezxml install directory")

# Create imported target for ezxml library
add_library(Ezxml::ezxml STATIC IMPORTED GLOBAL)
set_property(TARGET Ezxml::ezxml PROPERTY IMPORTED_LOCATION ${EZXML_INSTALL_DIR}/lib/libezxml.a)
add_dependencies(Ezxml::ezxml ezxml_project)

# Interface target for include directories
file(MAKE_DIRECTORY ${EZXML_INSTALL_DIR}/include) # Ensure directory exists at configure time
add_library(Ezxml INTERFACE IMPORTED GLOBAL)
target_include_directories(Ezxml INTERFACE ${EZXML_INSTALL_DIR}/include)
add_dependencies(Ezxml ezxml_project)

set(EZXML_INCLUDE_DIR ${EZXML_INSTALL_DIR}/include CACHE INTERNAL "Ezxml include directory")
set(EZXML_LIBRARY_DIR ${EZXML_INSTALL_DIR}/lib CACHE INTERNAL "Ezxml library directory")
