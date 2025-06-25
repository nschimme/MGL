# enum_parser CMakeLists.txt

# Gather source files
file(GLOB ENUM_PARSER_SOURCES "*.c")

# Add executable for enum_parser
add_executable(enum_parser ${ENUM_PARSER_SOURCES})

# enum_parser uses ezxml.
# We need to link against the ezxml library built by ExternalProject.
target_include_directories(enum_parser PRIVATE
    ${EZXML_INCLUDE_DIR} # Direct include path from ExternalEzxml.cmake
)
target_link_libraries(enum_parser PRIVATE Ezxml::ezxml)

# Ensure ezxml is built before enum_parser
add_dependencies(enum_parser ezxml_project)

# Installation (optional)
install(TARGETS enum_parser DESTINATION bin)
