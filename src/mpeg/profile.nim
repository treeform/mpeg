## Optional Fluffy instrumentation for single-threaded profiling builds.
when defined(mpegProfile):
  import fluffy/measure

  proc pushScope(name: string) {.raises: [].} =
    try:
      measurePush(name)
    except KeyError as error:
      raise newException(AssertionDefect, error.msg)

template profileScope*(name: static string, detail: static bool = false) =
  when defined(mpegProfile) and (not detail or defined(mpegProfileDetail)):
    pushScope(name)
    defer: measurePop()
