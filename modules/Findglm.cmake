include(CFetch)

cfetch_header_dependency(
  "g-truc/glm@2929ad5a663597139276c10ef905d91e568fdc48"
  FILTER
  "glm"
  RENAME
  "glm=include/glm"
  INCLUDE_DIRECTORIES
  "include"
  LICENSE_FILE
  "copying.txt")
