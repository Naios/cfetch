# Use explicitly pinned versions (optional)
include(PackageLock.cmake)

find_package(continuable REQUIRED)
find_package(fmt REQUIRED)
find_package(imgui REQUIRED)
find_package(Threads REQUIRED)

add_executable(main "${CMAKE_CURRENT_LIST_DIR}/main.cpp")

target_link_libraries(main PUBLIC Threads::Threads)
target_link_libraries(main PUBLIC fmt::fmt continuable::continuable)
target_link_libraries(main PUBLIC imgui::imgui)
