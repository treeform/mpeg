# Raw packets and decoded planes expose stable pointers through the low-level API.
template `[]`[T: SomeNumber](p: ptr T, i: SomeInteger): var T =
  system.`[]`(cast[ptr UncheckedArray[T]](p), i)

template `[]=`[T: SomeNumber](p: ptr T, i: SomeInteger, value: T) =
  system.`[]=`(cast[ptr UncheckedArray[T]](p), i, value)

template `+`[T: SomeNumber](p: ptr T, offset: SomeInteger): ptr T =
  addr(p[offset])

# The original memory constructor accepts ownership of a malloc allocation.
proc freeExternal(p: pointer) {.importc: "free", header: "<stdlib.h>".}
