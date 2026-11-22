# Bundled PL_MPEG

Source: https://github.com/phoboslab/pl_mpeg

Revision: `c871f2be022ece7ef4f64230b4fb8e1fb9eb6023`, dated 2025-12-30.

The upstream decoder is MIT licensed. Its copyright and license are preserved
in the adjacent LICENSE file. The Nim wrapper has its own root license.

The bundled header has one local change in `plm_video_decode`: drain the
pending reference frame at EOF even when the last coded picture is a B-frame.
Upstream only drains it when the last coded picture is an I- or P-frame,
dropping the final display frame in `tests/data/stereo.mpg`. The regression
tests require all 60 frames and verify the last frame against FFmpeg.

`mpeg.h` includes stdio before the upstream header declares FILE-based APIs.
`pl_mpeg.c` enables the single-header implementation in one translation unit.
The Nim bindings use the default interleaved audio layout. Do not define
`PLM_AUDIO_SEPARATE_CHANNELS` or `PLM_NO_STDIO` with these bindings.

When replacing the upstream header, reapply or retire the EOF fix, review all
public declarations in `bindings.nim`, and run `nim r -f tests/tests.nim`.
The force flag avoids reusing a C object compiled against the previous header.
