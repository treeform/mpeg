# BT.601 limited-range YCbCr, with one chroma sample per 2x2 luma pixels.
proc convertFrame(frame: ptr plm_frame_t, dest: ptr uint8, stride: cint,
    pixelSize, red, green, blue: static int) =
  let
    pixels = cast[ptr UncheckedArray[uint8]](dest)
    luma = cast[ptr UncheckedArray[uint8]](frame.y.data)
    cb = cast[ptr UncheckedArray[uint8]](frame.cb.data)
    cr = cast[ptr UncheckedArray[uint8]](frame.cr.data)
  for row in 0 ..< int(frame.height):
    for col in countup(0, int(frame.width) - 1, 2):
      let
        u = int(cb[(row div 2) * int(frame.cb.width) + col div 2]) - 128
        v = int(cr[(row div 2) * int(frame.cr.width) + col div 2]) - 128
        r = (v * 104597) shr 16
        g = (u * 25674 + v * 53278) shr 16
        b = (u * 132201) shr 16
      for x in col .. min(col + 1, int(frame.width) - 1):
        let
          y = ((int(luma[row * int(frame.y.width) + x]) - 16) * 76309) shr 16
          i = row * int(stride) + x * pixelSize
        pixels[i + red] = uint8(clamp(y + r, 0, 255))
        pixels[i + green] = uint8(clamp(y - g, 0, 255))
        pixels[i + blue] = uint8(clamp(y + b, 0, 255))

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
