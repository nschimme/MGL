cmake_minimum_required(VERSION 3.15)
project(MGL VERSION 1.0 LANGUAGES C CXX) # Removed OBJC OBJCXX for now

if(APPLE)
    enable_language(OBJC OBJCXX)
    set(CMAKE_OBJC_STANDARD 11)
    set(CMAKE_OBJCXX_STANDARD 14)
    set(CMAKE_OBJC_FLAGS "${CMAKE_OBJC_FLAGS} -Wall -gfull -O2")
    set(CMAKE_OBJCXX_FLAGS "${CMAKE_OBJCXX_FLAGS} -Wall -gfull -O2")
    if(NOT WIN32) # Should be APPLE here
      set(CMAKE_OBJC_FLAGS "${CMAKE_OBJC_FLAGS} -fPIC")
      set(CMAKE_OBJCXX_FLAGS "${CMAKE_OBJCXX_FLAGS} -fPIC")
    endif()
    set(CMAKE_OBJC_FLAGS "${CMAKE_OBJC_FLAGS} -arch ${CMAKE_HOST_SYSTEM_PROCESSOR}")
    set(CMAKE_OBJCXX_FLAGS "${CMAKE_OBJCXX_FLAGS} -arch ${CMAKE_HOST_SYSTEM_PROCESSOR}")

    # Sanitizer for ObjC/ObjCXX
    if(MGL_ENABLE_SANITIZER AND APPLE)
        set(CMAKE_OBJC_FLAGS "${CMAKE_OBJC_FLAGS} -fsanitize=address")
        set(CMAKE_OBJCXX_FLAGS "${CMAKE_OBJCXX_FLAGS} -fsanitize=address")
    endif()
    message(STATUS "Final CMAKE_OBJC_FLAGS: ${CMAKE_OBJC_FLAGS}")
    message(STATUS "Final CMAKE_OBJCXX_FLAGS: ${CMAKE_OBJCXX_FLAGS}")
endif()

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 14)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# Common compiler flags
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -gfull -O2")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -gfull -O2")
set(CMAKE_OBJC_FLAGS "${CMAKE_OBJC_FLAGS} -Wall -gfull -O2")
set(CMAKE_OBJCXX_FLAGS "${CMAKE_OBJCXX_FLAGS} -Wall -gfull -O2")

# Add -fPIC for position independent code, required for shared libraries on some platforms
if(NOT WIN32)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC")
    set(CMAKE_OBJC_FLAGS "${CMAKE_OBJC_FLAGS} -fPIC")
    set(CMAKE_OBJCXX_FLAGS "${CMAKE_OBJCXX_FLAGS} -fPIC")
endif()

# macOS specific settings
if(CMAKE_SYSTEM_NAME MATCHES "Darwin")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -arch ${CMAKE_HOST_SYSTEM_PROCESSOR}")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -arch ${CMAKE_HOST_SYSTEM_PROCESSOR}")
    set(CMAKE_OBJC_FLAGS "${CMAKE_OBJC_FLAGS} -arch ${CMAKE_HOST_SYSTEM_PROCESSOR}")
    set(CMAKE_OBJCXX_FLAGS "${CMAKE_OBJCXX_FLAGS} -arch ${CMAKE_HOST_SYSTEM_PROCESSOR}")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -arch ${CMAKE_HOST_SYSTEM_PROCESSOR}")
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -arch ${CMAKE_HOST_SYSTEM_PROCESSOR}")

    # Frameworks
    find_library(METAL_FRAMEWORK Metal)
    find_library(OPENGL_FRAMEWORK OpenGL)
    find_library(FOUNDATION_FRAMEWORK Foundation)
    find_library(IOKIT_FRAMEWORK IOKit) # Often needed by GLFW
    find_library(COREVIDEO_FRAMEWORK CoreVideo) # Often needed by GLFW
    find_library(COCOA_FRAMEWORK Cocoa) # For GLFW windowing

    set(SYSTEM_FRAMEWORKS
        ${METAL_FRAMEWORK}
        ${OPENGL_FRAMEWORK}
        ${FOUNDATION_FRAMEWORK}
        ${IOKIT_FRAMEWORK}
        ${COREVIDEO_FRAMEWORK}
        ${COCOA_FRAMEWORK}
    )
endif()

# Include ExternalProject module
include(ExternalProject)

# External Dependencies
include(cmake/ExternalSPIRVCross.cmake)
include(cmake/ExternalSPIRVTools.cmake)
include(cmake/ExternalSPIRVHeaders.cmake)
include(cmake/ExternalGlslang.cmake)
include(cmake/ExternalGLFW.cmake)
include(cmake/ExternalEzxml.cmake)
include(cmake/ExternalGLM.cmake)
include(cmake/ExternalOpenGLRegistry.cmake) # Added for spec_parser

# Subdirectories
add_subdirectory(MGL)
add_subdirectory(MGL_Tests)
add_subdirectory(enum_parser)
add_subdirectory(spec_parser)
add_subdirectory(test_mgl)

message(STATUS "CMAKE_HOST_SYSTEM_PROCESSOR: ${CMAKE_HOST_SYSTEM_PROCESSOR}")
message(STATUS "CMAKE_C_COMPILER: ${CMAKE_C_COMPILER}")
message(STATUS "CMAKE_CXX_COMPILER: ${CMAKE_CXX_COMPILER}")
message(STATUS "CMAKE_OBJC_COMPILER: ${CMAKE_OBJC_COMPILER}")
message(STATUS "CMAKE_OBJCXX_COMPILER: ${CMAKE_OBJCXX_COMPILER}")
message(STATUS "SDK_ROOT: $ENV{SDKROOT}")
message(STATUS "System Frameworks: ${SYSTEM_FRAMEWORKS}")

# Option for sanitizer
option(MGL_ENABLE_SANITIZER "Enable address sanitizer" OFF)
if(MGL_ENABLE_SANITIZER)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fsanitize=address")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=address")
    set(CMAKE_OBJC_FLAGS "${CMAKE_OBJC_FLAGS} -fsanitize=address")
    set(CMAKE_OBJCXX_FLAGS "${CMAKE_OBJCXX_FLAGS} -fsanitize=address")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fsanitize=address")
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -fsanitize=address")
endif()

# Print final C flags
message(STATUS "Final CMAKE_C_FLAGS: ${CMAKE_C_FLAGS}")
message(STATUS "Final CMAKE_CXX_FLAGS: ${CMAKE_CXX_FLAGS}")
message(STATUS "Final CMAKE_OBJC_FLAGS: ${CMAKE_OBJC_FLAGS}")
message(STATUS "Final CMAKE_OBJCXX_FLAGS: ${CMAKE_OBJCXX_FLAGS}")
message(STATUS "Final CMAKE_EXE_LINKER_FLAGS: ${CMAKE_EXE_LINKER_FLAGS}")
message(STATUS "Final CMAKE_SHARED_LINKER_FLAGS: ${CMAKE_SHARED_LINKER_FLAGS}")

enable_testing()
