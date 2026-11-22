# BT.601 limited-range YCbCr, with one chroma sample per 2x2 luma pixels.
{.push raises: [].}
# All BT.601 channel sums for 8-bit input fall in -278..534.
const
  clipBias = 278
  biasedLuma = block:
    var luma: array[256, int16]
    for i in 0..<luma.len:
      luma[i] = int16(clipBias + (((i - 16) * 76309) shr 16))
    luma
  clipTable = block:
    var clipped: array[clipBias + 534 + 1, uint8]
    for i in low(clipped)..high(clipped):
      clipped[i] = uint8(clamp(i - clipBias, 0, 255))
    clipped

proc convertFrame(frame: ptr plm_frame_t, dest: ptr uint8, stride: cint,
    pixelSize, red, green, blue: static int, opaque: static bool = false) =
  let
    width = int(frame.width)
    height = int(frame.height)
    yStride = int(frame.y.width)
  template convertRows(row: int, secondRow: static bool) =
    let
      yRow = frame.y.data + row * yStride
      cbRow = frame.cb.data + (row div 2) * int(frame.cb.width)
      crRow = frame.cr.data + (row div 2) * int(frame.cr.width)
      dstRow = dest + row * int(stride)

    # Each full tile fits in the display rectangle. The last column and last
    # row use separate specializations. Channel math fits in signed 32 bits.
    {.push checks: off.}
    template tile(x: int, secondCol: static bool) =
      let
        u = int32(cbRow[x div 2]) - 128
        v = int32(crRow[x div 2]) - 128
        r = (v * 104597) shr 16
        g = (u * 25674 + v * 53278) shr 16
        b = (u * 132201) shr 16
      template pixel(srcIndex, dstIndex: int) =
        let y = int32(biasedLuma[yRow[srcIndex]])
        dstRow[dstIndex + red] = clipTable[y + r]
        dstRow[dstIndex + green] = clipTable[y - g]
        dstRow[dstIndex + blue] = clipTable[y + b]
        when opaque:
          dstRow[dstIndex + 3] = 255'u8
      let i = x * pixelSize
      pixel(x, i)
      when secondCol: pixel(x + 1, i + pixelSize)
      when secondRow:
        pixel(x + yStride, i + int(stride))
        when secondCol: pixel(x + yStride + 1, i + int(stride) + pixelSize)
    for col in 0 ..< width div 2:
      tile(2 * col, true)
    if (width and 1) != 0:
      tile(width - 1, false)
    {.pop.}

  for row in 0 ..< height div 2:
    convertRows(2 * row, true)
  if (height and 1) != 0:
    convertRows(height - 1, false)

proc frameToOpaqueRgba*(frame: ptr plm_frame_t, dest: ptr uint8, stride: cint) =
  ## Writes RGBA8 with alpha 255 into the supplied rows.
  convertFrame(frame, dest, stride, 4, 0, 1, 2, true)

proc plm_frame_to_rgb*(frame: ptr plm_frame_t, dest: ptr uint8, stride: cint) {.cdecl.} =
  convertFrame(frame, dest, stride, 3, 0, 1, 2)

proc plm_frame_to_bgr*(frame: ptr plm_frame_t, dest: ptr uint8, stride: cint) {.cdecl.} =
  convertFrame(frame, dest, stride, 3, 2, 1, 0)

proc plm_frame_to_rgba*(frame: ptr plm_frame_t, dest: ptr uint8, stride: cint) {.cdecl.} =
  convertFrame(frame, dest, stride, 4, 0, 1, 2)

proc plm_frame_to_bgra*(frame: ptr plm_frame_t, dest: ptr uint8, stride: cint) {.cdecl.} =
  convertFrame(frame, dest, stride, 4, 2, 1, 0)

proc plm_frame_to_argb*(frame: ptr plm_frame_t, dest: ptr uint8, stride: cint) {.cdecl.} =
  convertFrame(frame, dest, stride, 4, 1, 2, 3)

proc plm_frame_to_abgr*(frame: ptr plm_frame_t, dest: ptr uint8, stride: cint) {.cdecl.} =
  convertFrame(frame, dest, stride, 4, 3, 2, 1)
{.pop.}
