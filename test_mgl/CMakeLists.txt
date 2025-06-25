# test_mgl (for test_mgl_glfw) CMakeLists.txt

if(NOT APPLE)
    # This target is configured as a macOS App Bundle and uses entitlements,
    # making it highly specific to macOS.
    message(STATUS "Skipping test_mgl_glfw (macOS App Bundle test) build on non-Apple platform.")
    return()
endif()

# Source file: main.cpp
file(GLOB TEST_MGL_GLFW_SOURCES "*.cpp")

if(NOT TEST_MGL_GLFW_SOURCES)
    message(WARNING "No source files found for test_mgl_glfw. Executable will not be built.")
    return()
endif()

add_executable(test_mgl_glfw ${TEST_MGL_GLFW_SOURCES})

# Include directories
target_include_directories(test_mgl_glfw PRIVATE
    "${CMAKE_SOURCE_DIR}/MGL/include" # MGL headers
    ${GLFW_INCLUDE_DIR}               # GLFW headers
    ${GLM_INCLUDE_DIR}                # GLM headers
    # Potentially SPIRV-Cross/Tools/glslang includes if main.cpp uses them directly
    ${SPIRV_CROSS_INCLUDE_DIR}
    ${SPIRV_TOOLS_INCLUDE_DIR}
    ${GLSLANG_INCLUDE_DIR}
)

# Link against MGL, GLFW, and other dependencies
target_link_libraries(test_mgl_glfw
    PRIVATE
        MGL
        GLFW::glfw
        GLM
        # External shader compilation libraries if main.cpp uses them directly
        # Typically, MGL library would encapsulate shader compilation.
        # If main.cpp does its own compilation with these tools, then link:
        SPIRV-Cross::spirv-cross-glsl # Example, if it uses SPIRV-Cross directly
        Glslang::glslang              # Example, if it uses glslang directly
        SPIRV-Tools::SPIRV-Tools      # Example
        # System Frameworks (macOS)
        ${SYSTEM_FRAMEWORKS}
)

# Ensure dependencies are built first
add_dependencies(test_mgl_glfw MGL glfw_project glm_project spirv_cross_project glslang_project spirv_tools_project)

# macOS specific settings for test_mgl_glfw
if(CMAKE_SYSTEM_NAME MATCHES "Darwin")
    # This executable might need to be a MACOSX_BUNDLE to run correctly,
    # especially if it's a graphical GLFW application.
    set_target_properties(test_mgl_glfw PROPERTIES MACOSX_BUNDLE TRUE)

    # Create a basic Info.plist for the bundle if one doesn't exist
    set(TEST_MGL_GLFW_INFO_PLIST ${CMAKE_CURRENT_BINARY_DIR}/Info.plist)
    configure_file(
        "${CMAKE_SOURCE_DIR}/cmake/MacOSXBundleInfo.plist.in"
        ${TEST_MGL_GLFW_INFO_PLIST}
        @ONLY
    )
    set_target_properties(test_mgl_glfw PROPERTIES
        MACOSX_BUNDLE_INFO_PLIST ${TEST_MGL_GLFW_INFO_PLIST}
    )

    # Handle the entitlements file
    set(ENTITLEMENTS_FILE ${CMAKE_SOURCE_DIR}/test_mgl_glfw.entitlements)
    if(EXISTS ${ENTITLEMENTS_FILE})
        message(STATUS "Found entitlements file: ${ENTITLEMENTS_FILE}")
        # Apply entitlements using linker flags
        # This method is common for command-line specified entitlements.
        # For Xcode, it's often handled in build settings. CMake can pass linker flags.
        set_property(TARGET test_mgl_glfw APPEND_STRING PROPERTY LINK_FLAGS
            " -Wl,-sectcreate,__TEXT,__entitlements,${ENTITLEMENTS_FILE}")
    else()
        message(WARNING "Entitlements file not found: ${ENTITLEMENTS_FILE}")
    endif()
endif()

# Add as a test to CTest
add_test(NAME test_mgl_glfw COMMAND test_mgl_glfw)
# Set working directory if needed, e.g., for loading resources
# set_tests_properties(test_mgl_glfw PROPERTIES WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})


# Installation (optional, usually test executables are not installed)
# install(TARGETS test_mgl_glfw DESTINATION bin/tests)

message(STATUS "test_mgl_glfw Sources: ${TEST_MGL_GLFW_SOURCES}")
