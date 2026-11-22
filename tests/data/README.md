# Synthetic MPEG fixtures

These fixtures are generated from FFmpeg test patterns and sine waves by
`nim r tools/gen_fixtures.nim`. They contain no downloaded media and are
distributed under this repository's MIT license.

- `stereo.mpg`: 60 frames at 30 fps, 162x98 pixels, B-frames, stereo MP2 at
  48000 Hz. Left is a 440 Hz sine at amplitude 0.25, right is an 880 Hz sine
  at amplitude 0.125. MP2 padding produces 84 packets of 1152 sample frames.
- `stereo.rgb` and `stereo-last.rgb`: FFmpeg's first and last decoded frames
  as packed RGB24, with no headers.
- `stereo.f32`: FFmpeg's first six decoded audio packets as interleaved
  little-endian float32 stereo PCM. These references detect channel swaps,
  inverted phase, and the low output volume in older PL_MPEG versions.
- `video.mpg`: 12 frames at 25 fps, 64x48 pixels, without audio or B-frames.
- `mono.mpg`: 24 frames at 24 fps, 64x48 pixels, mono MP2 at 44100 Hz.

The checked-in files let the normal tests run offline without FFmpeg or an
audio device. FFmpeg is only needed to regenerate the fixtures. Encoding
details may vary between FFmpeg versions, so review reference changes and
run the full suite after regeneration.
