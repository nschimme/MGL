# MGL_Tests CMakeLists.txt

if(NOT APPLE)
    message(STATUS "Skipping MGL_Tests build on non-Apple platform.")
    return()
endif()

# Gather test source files
# Based on ls output: MGL_Tests/MGL_Tests.mm, MGL_Tests/MGL_test_utils.h, MGL_Tests/MGL_test_utils.mm
file(GLOB MGL_TEST_SOURCES
    "*.mm"
    # "*.cpp" # Add if there are C++ test files
    # "*.c"   # Add if there are C test files
)

if(NOT MGL_TEST_SOURCES)
    message(WARNING "No source files found for MGL_Tests. Test executable will not be built.")
    return()
endif()

# Add executable for the tests
add_executable(MGLTests ${MGL_TEST_SOURCES})

# Include directories for MGL_Tests
target_include_directories(MGLTests PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}" # For MGL_test_utils.h
    "${CMAKE_SOURCE_DIR}/MGL/include" # To include MGL headers like mgl.h
    # Add include dirs from external dependencies if needed directly by tests
    ${GLFW_INCLUDE_DIR} # If tests use GLFW directly for windowing
    ${GLM_INCLUDE_DIR}
)

# Link MGLTests against MGL library and other dependencies
target_link_libraries(MGLTests
    PRIVATE
        MGL # Link against our MGL library
        GLFW::glfw # For windowing/context, if tests need it (likely for GL tests)
        GLM
        # System Frameworks (macOS) - inherited if MGL links them PUBLICLY,
        # or add them explicitly if tests use them directly.
        # MGL links SYSTEM_FRAMEWORKS privately, so tests might need them if they use Metal/OpenGL directly.
        ${SYSTEM_FRAMEWORKS}
)

# Ensure MGL library and other dependencies are built before the tests
add_dependencies(MGLTests MGL glfw_project glm_project) # Ensure GLM is also ready

# If test sources are Objective-C or Objective-C++ (.mm), set appropriate flags
# The .mm extension usually implies Objective-C++.
# The root CMakeLists.txt already enables OBJC and OBJCXX languages.
# If specific flags like ARC are needed for test files:
set_source_files_properties(${MGL_TEST_SOURCES}
    PROPERTIES COMPILE_FLAGS "-fobjc-arc -fmodules" # Common for Objective-C/Cocoa
)

# Define tests using add_test (CTest integration)
# The name "MGLTests" here is the CTest test name, can be different from executable name.
add_test(NAME MGLTests COMMAND MGLTests)

# The Makefile mentions test_mgl_glfw and an entitlements file.
# This MGLTests target seems to be for the tests in MGL_Tests folder.
# test_mgl_glfw might be a separate executable or covered by these tests.
# test_mgl_glfw.entitlements suggests a macOS application bundle might be needed for some tests,
# especially if they require specific permissions (e.g., Metal device access, user interaction).

# For now, MGLTests is a command-line executable.
# If it needs to be a macOS App bundle:
# set_target_properties(MGLTests PROPERTIES MACOSX_BUNDLE TRUE)
# set_target_properties(MGLTests PROPERTIES MACOSX_BUNDLE_INFO_PLIST path/to/Info.plist)
# The entitlements file test_mgl_glfw.entitlements would be specified via linker options:
# set_target_properties(MGLTests PROPERTIES LINK_FLAGS "-Wl,-sectcreate,__TEXT,__entitlements,${CMAKE_SOURCE_DIR}/test_mgl_glfw.entitlements")
# This is advanced and depends on how tests are run and what they do.
# The Makefile just builds an $(test_exe) and runs it.

# The MGL.xcodeproj has schemes for "test_mgl_glfw". This suggests it's an important test.
# The `test_mgl/main.cpp` seems to be the source for this. I'll handle that in `test_mgl/CMakeLists.txt`.
# This `MGL_Tests/CMakeLists.txt` is for the tests located directly in `MGL_Tests/` directory.

# Check for specific test resources like golden images
# MGL_Golden_Images/ directory exists. Tests might need to load these.
# We might need to copy these resources to the build directory where tests are run.
# Or configure tests to find them relative to source directory.
# CTest allows setting WORKING_DIRECTORY for tests.
set_tests_properties(MGLTests PROPERTIES WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/MGL_Golden_Images)
# This assumes test executable knows to look in its current working directory for these images.
# Alternatively, pass the path as an argument or environment variable.
# Example: COMMAND MGLTests --resource-path ${CMAKE_SOURCE_DIR}/MGL_Golden_Images

# TestImages/TestList.txt also exists. This might be an input to the test runner.
# If MGLTests executable takes this as an argument:
# add_test(NAME MGLTestsWithList COMMAND MGLTests ${CMAKE_SOURCE_DIR}/TestImages/TestList.txt)
# For now, keeping it simple with one test entry.

# Installation (optional, usually tests are not installed)
# install(TARGETS MGLTests DESTINATION bin/tests)

message(STATUS "MGL_Test Sources: ${MGL_TEST_SOURCES}")
message(STATUS "MGL_Test Working Directory for CTest: ${CMAKE_SOURCE_DIR}/MGL_Golden_Images")
