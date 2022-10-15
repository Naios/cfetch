include(CFetch)

cfetch_header_dependency(
  "fmtlib/fmt@b6f4ceaed0a0a24ccf575fab6c56dd50ccf6f1a9"
  DEFINITIONS
  FMT_HEADER_ONLY
  FMT_EXCEPTIONS=0
  LICENSE_FILE
  "LICENSE.rst"
  EXPORT)
