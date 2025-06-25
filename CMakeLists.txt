cmake_minimum_required(VERSION 3.16)

if(APPLE)
  project(QtMGLTest LANGUAGES CXX OBJCXX)
else()
  project(QtMGLTest LANGUAGES CXX)
endif()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt5 COMPONENTS Core Gui Widgets REQUIRED)

set(MGL_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/MGL/include") # Path to MGL headers
set(MGL_LIBRARY_DIR "${CMAKE_CURRENT_SOURCE_DIR}/MGL/lib") # Assumed path for libmgl.dylib

# Source files
set(PROJECT_SOURCES
    main.cpp
    mainwindow.h
    mainwindow.cpp
    openglwidget.h
    openglwidget.cpp
)

# Create the executable
add_executable(QtMGLTest ${PROJECT_SOURCES})

# Link Qt5
target_link_libraries(QtMGLTest PRIVATE Qt5::Core Qt5::Gui Qt5::Widgets)

# macOS specific settings
if(APPLE)
    message(STATUS "Configuring for macOS")
    target_include_directories(QtMGLTest PRIVATE ${MGL_INCLUDE_DIR})

    # For MGL library
    # Option 1: If libmgl.dylib is pre-built and placed in MGL/lib
    # target_link_directories(QtMGLTest PRIVATE ${MGL_LIBRARY_DIR})
    # target_link_libraries(QtMGLTest PRIVATE mgl)

    # Option 2: Link directly to the dylib if its path is known
    # For now, assuming it will be found by the linker via rpath or standard paths
    # or will be added to the build process of MGL itself later.
    # For development, you might place libmgl.dylib in the build directory or a known system path.
    # We will assume for now that MGL is built as part of the same super-project or installed system-wide.
    # A placeholder for linking MGL - this will need adjustment based on how MGL is actually built/found.
    # If MGL is built as a separate CMake target: target_link_libraries(QtMGLTest PRIVATE MGL::MGL)

    target_link_libraries(QtMGLTest PRIVATE "-framework AppKit")
    target_link_libraries(QtMGLTest PRIVATE "-framework Foundation")
    target_link_libraries(QtMGLTest PRIVATE "-framework QuartzCore") # For CAMetalLayer etc.
    target_link_libraries(QtMGLTest PRIVATE "-framework Metal")

    # Specify that openglwidget.cpp should be compiled as Objective-C++
    set_source_files_properties(openglwidget.cpp PROPERTIES
        COMPILE_FLAGS "-ObjC++"
        LANGUAGE OBJCXX)

    # Add rpath for MGL library if it's in a relative path
    # target_link_options(QtMGLTest PRIVATE "-Wl,-rpath,${MGL_LIBRARY_DIR}") # If lib is in MGL/lib
    # Or if MGL is built alongside in the build directory:
    # target_link_options(QtMGLTest PRIVATE "-Wl,-rpath,@executable_path/../MGL_Build_Dir_Relative_Path")


    # For now, we will assume libmgl.dylib must be findable by the dynamic linker at runtime.
    # This typically means it's in the same directory as the executable,
    # in a directory listed in DYLD_LIBRARY_PATH, or in a standard system location.
    # Or, if MGL itself were a CMake project, we'd link to its target.
    # The GLFW example mentioned "libmgl.dylib", so we'll add a manual link flag for it.
    # This assumes libmgl.dylib will be in a location the linker can find (e.g., /usr/local/lib or via -L)
    # For a self-contained project, we'd typically ensure MGL is built and its library output path is known.
    # Adding a find_library command for MGL
    find_library(MGL_LIBRARY NAMES mgl HINTS ${MGL_LIBRARY_DIR} "${CMAKE_BINARY_DIR}" "/usr/local/lib" "${CMAKE_CURRENT_SOURCE_DIR}/MGL" )

    if(MGL_LIBRARY)
        message(STATUS "Found MGL library: ${MGL_LIBRARY}")
        target_link_libraries(QtMGLTest PRIVATE ${MGL_LIBRARY})

        # If MGL_LIBRARY_DIR is where the .dylib is, and it's not a standard path, add it to rpath
        get_filename_component(MGL_LIB_PATH ${MGL_LIBRARY} DIRECTORY)
        if(IS_DIRECTORY ${MGL_LIB_PATH} AND NOT MGL_LIB_PATH STREQUAL "/usr/local/lib" AND NOT MGL_LIB_PATH STREQUAL "/usr/lib")
            message(STATUS "Adding rpath for MGL: ${MGL_LIB_PATH}")
            target_link_options(QtMGLTest PRIVATE "-Wl,-rpath,${MGL_LIB_PATH}")
        endif()
    else()
        message(WARNING "libmgl.dylib not found. macOS build might fail to link or run correctly if MGL is used.")
        # Fallback: try to link 'mgl' and hope it's in default linker paths
        target_link_libraries(QtMGLTest PRIVATE "-lmgl")
    endif()

else()
    message(STATUS "Configuring for non-macOS")
    # No MGL specific settings for other platforms
endif()

# Define preprocessor macros for OS detection if needed in C++
if(APPLE)
    target_compile_definitions(QtMGLTest PRIVATE USING_MGL_ON_MACOS)
endif()

# Create dummy MGL include and lib directories for now for CMake to not fail
# In a real scenario, MGL would be a submodule or an installed package.
file(MAKE_DIRECTORY ${MGL_INCLUDE_DIR})
file(MAKE_DIRECTORY ${MGL_LIBRARY_DIR})
# Create a dummy mgl.h for cmake to pass during configuration
file(WRITE ${MGL_INCLUDE_DIR}/mgl.h "// Dummy MGL header for CMake configuration\n#ifndef MGL_H\n#define MGL_H\nvoid mglSwapBuffers(void* ctx);\nvoid* createGLMContext(int, int, int, int, int, int);\nvoid MGLsetCurrentContext(void* ctx);\n#endif\n")
# Create a dummy libmgl.dylib for cmake to pass find_library on macOS
if(APPLE)
    file(WRITE ${MGL_LIBRARY_DIR}/libmgl.dylib "")
endif()

# For handling Objective-C++ files correctly with CMake's AUTOMOC
# If openglwidget.h includes Q_OBJECT, it might generate moc_openglwidget.cpp
# We need to ensure that if openglwidget.cpp is OBJCXX, its moc file is also handled appropriately.
# CMAKE_AUTOMOC usually handles this well, but good to be aware.
# If there are issues, one might need to explicitly set the language for the moc file:
# set_source_files_properties(${CMAKE_CURRENT_BINARY_DIR}/QtMGLTest_autogen/moc_openglwidget.cpp PROPERTIES LANGUAGE CXX)
# However, since openglwidget.h itself won't be ObjC++, this should be fine.
# The ObjC++ requirement is for the .cpp/.m file that implements MGL calls.

# Ensure the MGL include directory from the source tree is available
target_include_directories(QtMGLTest PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}" # Allows includes like "mgl/include/..."
)

# On macOS, ensure @executable_path/../Frameworks is an rpath for Qt frameworks if they are bundled
if(APPLE AND CMAKE_INSTALL_PREFIX)
    set(CMAKE_MACOSX_RPATH TRUE)
    set(CMAKE_INSTALL_RPATH "@executable_path/../Frameworks")
endif()

message(STATUS "CMake project configured. MGL Path: ${MGL_INCLUDE_DIR}, MGL Lib: ${MGL_LIBRARY}")

# Add AGENTS.md to the list of files to ensure it's part of the project context if needed later.
# (Though it's not a source file for compilation)
# list(APPEND PROJECT_FILES AGENTS.md) # If AGENTS.md exists and is relevant.

# Placeholder for MGL build if it were a subdirectory CMake project
# add_subdirectory(MGL) # Assuming MGL/CMakeLists.txt exists
# And then link: target_link_libraries(QtMGLTest PRIVATE MGL::MGL) # Or whatever target MGL defines
