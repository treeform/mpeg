# Apple M1 results

Nim 2.2.10, release, stereo.mpg, ten runs.

Audio decode + PCM: portable 1.966 ms (SD 0.015), NEON 1.317 ms (SD 0.014): 1.49x speedup.
Video decode + RGBA: portable 11.487 ms (SD 4.891), NEON 11.760 ms (SD 5.017): no demonstrated improvement.

All 24 tests pass in debug, release and nimAllocStats builds. 512 randomized NEON synthesis cases match portable output exactly. Decode example runs: 60 video frames and 96768 audio sample frames.

Benchmark commands: nim r -d:release --passC:-Wno-int-conversion tests/bench_mpeg.nim, adding -d:mpegNoSimd for baseline. The flag works around an upstream benchy pointer/integer conversion error in Apple Clang.

NEON accelerates MP2 synthesis only. These are native hardware measurements, not instruction simulator predictions.

## Follow-up: video conversion and warmed measurements

The original NEON implementation omitted both video kernels accelerated by AVX2. Added exact-integer NEON opaque RGBA conversion, with portable tails and odd-row handling. IDCT and reconstruction remain portable.

With -d:benchyExtra (15 warmup runs), ten measured runs:
- Portable video: 7.384 ms mean, 0.010 ms SD.
- NEON video: 6.789 ms mean, 0.008 ms SD (1.088x, 8.1% less time).
- Portable audio: 2.001 ms mean, 0.003 ms SD.
- NEON audio: 1.313 ms mean, 0.003 ms SD (1.524x).

All 24 release and debug tests pass after the conversion change. Initial video timings included cold-start variance and should not be used to estimate throughput. No AVX2 measurements were made locally on this ARM Mac.
