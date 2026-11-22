## Only this module is compiled for AVX2. Callers dispatch before entering it.
import nimsimd/avx2

when defined(vcc):
  {.localPassC: "/arch:AVX2 /fp:strict".}
else:
  {.localPassC: "-mavx2 -ffp-contract=off".}

type Bytes = ptr UncheckedArray[uint8]

{.push checks: off, raises: [].}
proc opaqueRgbaRowsAvx2*(y0, y1, cb, cr, dest0, dest1: ptr uint8, width: int) =
  ## Convert full groups of 32 pixels on two rows sharing the same chroma.
  let
    zero = mm256_setzero_si256()
    bias = mm256_set1_epi16(128)
    alpha = mm256_set1_epi8(255'u8)
    greenWeights = mm256_set1_epi32((uint32(cast[uint16](-12258'i16)) shl 16) or 25674'u32)
  for group in 0..<width div 32:
    let
      x = group * 32
      u = mm256_sub_epi16(mm256_cvtepu8_epi16(mm_loadu_si128(addr cast[Bytes](cb)[x div 2])), bias)
      v = mm256_sub_epi16(mm256_cvtepu8_epi16(mm_loadu_si128(addr cast[Bytes](cr)[x div 2])), bias)
      # Factor the original 16.16 coefficients into an integer part and a
      # signed fraction. Green's two products share a single rounding shift.
      r = mm256_add_epi16(mm256_add_epi16(v, v), mm256_mulhi_epi16(v, mm256_set1_epi16(-26475)))
      b = mm256_add_epi16(mm256_add_epi16(u, u), mm256_mulhi_epi16(u, mm256_set1_epi16(1129)))
      g0 = mm256_madd_epi16(mm256_unpacklo_epi16(u, v), greenWeights)
      g1 = mm256_madd_epi16(mm256_unpackhi_epi16(u, v), greenWeights)
      g = mm256_add_epi16(v, mm256_packs_epi32(mm256_srai_epi32(g0, 16), mm256_srai_epi32(g1, 16)))

    template writeRow(y, dest: ptr uint8) =
      block:
        let yBytes = mm256_loadu_si256(addr cast[Bytes](y)[x])
        template luma(words: M256i): M256i =
          let t = mm256_sub_epi16(words, mm256_set1_epi16(16))
          mm256_add_epi16(t, mm256_mulhi_epi16(t, mm256_set1_epi16(10773)))
        let
          lo = luma(mm256_unpacklo_epi8(yBytes, zero))
          hi = luma(mm256_unpackhi_epi8(yBytes, zero))
        template channel(chroma, combine: untyped): M256i =
          mm256_packus_epi16(combine(lo, mm256_unpacklo_epi16(chroma, chroma)),
                             combine(hi, mm256_unpackhi_epi16(chroma, chroma)))
        let
          red = channel(r, mm256_add_epi16)
          green = channel(g, mm256_sub_epi16)
          blue = channel(b, mm256_add_epi16)
          rg0 = mm256_unpacklo_epi8(red, green)
          rg1 = mm256_unpackhi_epi8(red, green)
          ba0 = mm256_unpacklo_epi8(blue, alpha)
          ba1 = mm256_unpackhi_epi8(blue, alpha)
          p0 = mm256_unpacklo_epi16(rg0, ba0)
          p1 = mm256_unpackhi_epi16(rg0, ba0)
          p2 = mm256_unpacklo_epi16(rg1, ba1)
          p3 = mm256_unpackhi_epi16(rg1, ba1)
        template store(offset: int, value: M256i) =
          mm256_storeu_si256(addr cast[Bytes](dest)[x * 4 + offset], value)
        store(0, mm256_permute2x128_si256(p0, p1, 0x20))
        store(32, mm256_permute2x128_si256(p2, p3, 0x20))
        store(64, mm256_permute2x128_si256(p0, p1, 0x31))
        store(96, mm256_permute2x128_si256(p2, p3, 0x31))
    writeRow(y0, dest0)
    writeRow(y1, dest1)
{.pop.}
