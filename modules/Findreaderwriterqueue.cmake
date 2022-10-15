include(CFetch)

cfetch_header_dependency(
  "cameron314/readerwriterqueue@435e36540e306cac40fcfeab8cc0a22d48464509"
  RENAME
  "atomicops.h=include/readerwriterqueue/atomicops.h"
  "readerwriterqueue.h=include/readerwriterqueue/readerwriterqueue.h"
  FILTER
  "atomicops.h"
  "readerwriterqueue.h"
  INCLUDE_DIRECTORIES
  "include"
  LICENSE_FILE
  "LICENSE.md")
