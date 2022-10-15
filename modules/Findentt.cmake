include(CFetch)

cfetch_header_dependency(
  "skypjack/entt@d1d73da0399dd0471a31694d4f0eab55d73e41e8"
  FILTER
  "src"
  RENAME
  "src=include"
  INCLUDE_DIRECTORIES
  "include"
  LICENSE_FILE
  "LICENSE")
