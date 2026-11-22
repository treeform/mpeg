# Decoder provenance

The Nim decoder is a port of [PL_MPEG revision c871f2b](https://github.com/phoboslab/pl_mpeg/tree/c871f2be022ece7ef4f64230b4fb8e1fb9eb6023), dated 2025-12-30.
Dominic Szablewski's MIT copyright notice and license are in the adjacent LICENSE file.
Upstream credits Zoltan Korandi's Java MPEG-1 Video Decoder and Player for
inspiring its video decoder and Martin J. Fiedler's kjmp2 for its audio decoder.

The port retains the local end-of-stream fix that displays the pending reference
frame after a final B-picture. The RGB conversion routines also handle odd display
dimensions. File I/O and decoder-owned allocations use Nim's standard library.
The low-level memory constructor retains its original ownership contract.
Passing `free_when_done = 1` transfers a C `malloc` allocation to the decoder,
which releases it with the matching C runtime `free`.

Run `nim r tests/tests.nim` for the codec, container, and API regressions.
