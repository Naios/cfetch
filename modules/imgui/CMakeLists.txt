find_package(SDL2 REQUIRED)
find_package(glbinding REQUIRED)

add_library(
  imgui STATIC
  "${imgui_DIR}/imgui.cpp"
  "${imgui_DIR}/imgui_widgets.cpp"
  "${imgui_DIR}/imgui_draw.cpp"
  "${imgui_DIR}/imgui_tables.cpp"
  "${imgui_DIR}/imgui_demo.cpp"
  "${imgui_DIR}/backends/imgui_impl_sdl.cpp"
  "${imgui_DIR}/backends/imgui_impl_opengl3.cpp")

target_include_directories(imgui PUBLIC "${imgui_DIR}")

target_compile_definitions(imgui PUBLIC IMGUI_IMPL_OPENGL_LOADER_GLBINDING3=1
                                        SDL_MAIN_HANDLED=1)

target_link_libraries(imgui PUBLIC SDL2::SDL2 glbinding::glbinding)

add_library(imgui::imgui ALIAS imgui)
