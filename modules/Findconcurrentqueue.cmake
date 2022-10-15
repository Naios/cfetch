include(CFetch)

cfetch_header_dependency(
  "cameron314/concurrentqueue@9cfda6cc61065d016ae3f51f486ce0fae563ea87"
  FILTER
  "concurrentqueue.h"
  "blockingconcurrentqueue.h"
  "lightweightsemaphore.h"
  RENAME
  "concurrentqueue.h=include/concurrentqueue/concurrentqueue.h"
  "blockingconcurrentqueue.h=include/concurrentqueue/blockingconcurrentqueue.h"
  "lightweightsemaphore.h=include/concurrentqueue/lightweightsemaphore.h"
  INCLUDE_DIRECTORIES
  "include"
  LICENSE_FILE
  "LICENSE.md")
