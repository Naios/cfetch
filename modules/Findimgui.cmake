include(CFetch)

cfetch_dependency(
  "ocornut/imgui@7f38773b738e8d37b1a3c1d627205821300ef765" #
  SUBDIRECTORY
  "${CMAKE_CURRENT_LIST_DIR}/imgui" #
  PATCH
  "${CMAKE_CURRENT_LIST_DIR}/imgui/index32.patch" #
  LICENSE_FILE
  "LICENSE.txt")
