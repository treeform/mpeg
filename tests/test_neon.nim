## Exact comparison across every synthesis-ring phase, including wraparound.
import std/random
import mpeg/[simd, synthesis]
when buildNeon:
  import mpeg/kernels_neon
  var rng = initRand(42)
  var ring: array[1024, float32]
  var window: array[512, float32]
  for trial in 0..<32:
    for x in ring.mitems: x = float32(rng.rand(200000.0) - 100000.0)
    for x in window.mitems: x = float32(rng.rand(2000.0) - 1000.0)
    for pos in countup(0, 960, 64):
      var expected, actual: array[32, float32]
      synthesisWindowPortable(ring, window, pos, expected)
      synthesisWindowNeon(ring, window, pos, actual)
      doAssert actual == expected
  echo "512 NEON synthesis cases match portable output exactly"
