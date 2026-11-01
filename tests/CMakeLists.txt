find_package(Qt6Test ${QT_MIN_VERSION} REQUIRED)

add_executable(test_kdropover test_kdropover.cpp)
target_compile_definitions(test_kdropover PRIVATE KDROPOVER_SOURCE_DIR="${CMAKE_SOURCE_DIR}")
target_link_libraries(test_kdropover PRIVATE
    kdropover_core
    Qt6::Core
    Qt6::Qml
    Qt6::Test
)

add_test(NAME test_kdropover COMMAND test_kdropover)
