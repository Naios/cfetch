include(CFetch)

cfetch_header_dependency(
  "juliettef/IconFontCppHeaders@c7fc83a9ea8e803abd661230372155d7fe0d5128"
  RENAME
  "IconsFontAwesome5.h=include/IconFontCppHeaders/IconsFontAwesome5.h"
  FILTER
  "IconsFontAwesome5.h"
  INCLUDE_DIRECTORIES
  "include"
  LICENSE_FILE
  "licence.txt")
