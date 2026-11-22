## MP2 synthesis visits 16 taps for each group of 32 output samples.
## vPos is a multiple of 64 in 0..960. Each 32-element slice fits in
## the 512-entry window and 1024-entry history ring, including at wraparound.
when defined(vcc):
  {.localPassC: "/fp:strict".}
elif defined(gcc) or defined(clang):
  {.localPassC: "-fno-fast-math -ffp-contract=off".}

{.push checks: off, raises: [].}
iterator synthesisTaps*(vPos: int): tuple[w, v: int] =
  let
    windowBase = 512 - (vPos shr 1)
    phase = (vPos and 127) shr 1
  for half in 0..1:
    let vBase = if half == 0: phase else: 96 - phase
    for tap in 0..<8:
      yield ((windowBase + half * 32 + tap * 64) and 511, vBase + tap * 128)

proc synthesisWindowPortable*(ring: array[1024, float32], window: array[512, float32],
    vPos: int, samples: var array[32, float32]) =
  # Keep this in its own compilation unit so even FMA-capable targets round
  # each product before adding it, in the same order as the AVX2 kernel.
  reset samples
  for w, v in synthesisTaps(vPos):
    for i in 0..<32:
      samples[i] += window[w + i] * ring[v + i]
{.pop.}
