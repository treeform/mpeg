proc plm_video_decode_sequence_header(self: ptr plm_video_t): cint
proc plm_video_init_frame(self: ptr plm_video_t, frame: ptr plm_frame_t, base: ptr uint8)
proc plm_video_decode_picture(self: ptr plm_video_t)
proc plm_video_decode_slice(self: ptr plm_video_t, slice: cint)
proc plm_video_decode_macroblock(self: ptr plm_video_t)
proc plm_video_decode_motion_vectors(self: ptr plm_video_t)
proc plm_video_decode_motion_vector(self: ptr plm_video_t, rSize: cint, motion: cint): cint
proc plm_video_predict_macroblock(self: ptr plm_video_t)
proc plm_video_copy_macroblock(self: ptr plm_video_t, s: ptr plm_frame_t, motionH: cint, motionV: cint)
proc plm_video_interpolate_macroblock(self: ptr plm_video_t, s: ptr plm_frame_t, motionH: cint, motionV: cint)
proc plm_video_process_macroblock(self: ptr plm_video_t, s: ptr uint8, d: ptr uint8,
    motionH: cint, motionV: cint, blockSize: cint, interpolate: cint)
proc plm_video_decode_block(self: ptr plm_video_t, blockIndex: cint)
proc plm_video_idct(coefficients: var array[64, cint])

const PLM_VIDEO_PICTURE_TYPE_INTRA: cint = 1

const PLM_VIDEO_PICTURE_TYPE_PREDICTIVE: cint = 2

const PLM_VIDEO_PICTURE_TYPE_B: cint = 3

const PLM_START_SEQUENCE: cint = 0xB3

const PLM_START_SLICE_FIRST: cint = 0x01

const PLM_START_SLICE_LAST: cint = 0xAF

const PLM_START_PICTURE: cint = 0x00

const PLM_START_EXTENSION: cint = 0xB5

const PLM_START_USER_DATA: cint = 0xB2

const PLM_VIDEO_PIXEL_ASPECT_RATIO: array[14, float32] = [1.0000'f32, 0.6735'f32, 0.7031'f32,
    0.7615'f32, 0.8055'f32, 0.8437'f32, 0.8935'f32, 0.9157'f32, 0.9815'f32, 1.0255'f32,
    1.0695'f32, 1.0950'f32, 1.1575'f32, 1.2051'f32]

const PLM_VIDEO_PICTURE_RATE: array[16, float64] = [0.000, 23.976, 24.000, 25.000, 29.970, 30.000,
    50.000, 59.940, 60.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000]

const PLM_VIDEO_ZIG_ZAG: array[64, uint8] = [0, 1, 8, 16, 9, 2, 3, 10, 17, 24, 32, 25, 18, 11, 4,
    5, 12, 19, 26, 33, 40, 48, 41, 34, 27, 20, 13, 6, 7, 14, 21, 28, 35, 42, 49, 56, 57, 50, 43,
    36, 29, 22, 15, 23, 30, 37, 44, 51, 58, 59, 52, 45, 38, 31, 39, 46, 53, 60, 61, 54, 47, 55, 62, 63]

const PLM_VIDEO_INTRA_QUANT_MATRIX: array[64, uint8] = [8, 16, 19, 22, 26, 27, 29, 34, 16, 16, 22,
    24, 27, 29, 34, 37, 19, 22, 26, 27, 29, 34, 34, 38, 22, 22, 26, 27, 29, 34, 37, 40, 22, 26,
    27, 29, 32, 35, 40, 48, 26, 27, 29, 32, 35, 40, 48, 58, 26, 27, 29, 34, 38, 46, 56, 69, 27,
    29, 35, 38, 46, 56, 69, 83]

const PLM_VIDEO_NON_INTRA_QUANT_MATRIX: array[64, uint8] = [16, 16, 16, 16, 16, 16, 16, 16, 16,
    16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16,
    16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16,
    16, 16, 16, 16, 16, 16, 16, 16, 16]

const PLM_VIDEO_PREMULTIPLIER_MATRIX: array[64, uint8] = [32, 44, 42, 38, 32, 25, 17, 9, 44, 62,
    58, 52, 44, 35, 24, 12, 42, 58, 55, 49, 42, 33, 23, 12, 38, 52, 49, 44, 38, 30, 20, 10, 32,
    44, 42, 38, 32, 25, 17, 9, 25, 35, 33, 30, 25, 20, 14, 7, 17, 24, 23, 20, 17, 14, 9, 5, 9, 12,
    12, 10, 9, 7, 5, 2]

const PLM_VIDEO_MACROBLOCK_ADDRESS_INCREMENT: array[80, VlcNode] = [(2, 0), (0, 1), (4, 0), (6,
    0), (8, 0), (10, 0), (0, 3), (0, 2), (12, 0), (14, 0), (0, 5), (0, 4), (16, 0), (18, 0), (0,
    7), (0, 6), (20, 0), (22, 0), (24, 0), (26, 0), (28, 0), (30, 0), (32, 0), (34, 0), (36, 0), (
    38, 0), (0, 9), (0, 8), (-1, 0), (40, 0), (-1, 0), (42, 0), (44, 0), (46, 0), (0, 15), (0,
    14), (0, 13), (0, 12), (0, 11), (0, 10), (48, 0), (50, 0), (52, 0), (54, 0), (56, 0), (58, 0),
    (60, 0), (62, 0), (64, 0), (-1, 0), (-1, 0), (66, 0), (68, 0), (70, 0), (72, 0), (74, 0), (76,
    0), (78, 0), (0, 21), (0, 20), (0, 19), (0, 18), (0, 17), (0, 16), (0, 35), (-1, 0), (-1, 0),
    (0, 34), (0, 33), (0, 32), (0, 31), (0, 30), (0, 29), (0, 28), (0, 27), (0, 26), (0, 25), (0,
    24), (0, 23), (0, 22)]

const PLM_VIDEO_MACROBLOCK_TYPE_INTRA: array[4, VlcNode] = [(2, 0), (0, 0x01), (-1, 0), (0, 0x11)]

const PLM_VIDEO_MACROBLOCK_TYPE_PREDICTIVE: array[14, VlcNode] = [(2, 0), (0, 0x0a), (4, 0), (0,
    0x02), (6, 0), (0, 0x08), (8, 0), (10, 0), (12, 0), (0, 0x12), (0, 0x1a), (0, 0x01), (-1, 0),
    (0, 0x11)]

const PLM_VIDEO_MACROBLOCK_TYPE_B: array[22, VlcNode] = [(2, 0), (4, 0), (6, 0), (8, 0), (0,
    0x0c), (0, 0x0e), (10, 0), (12, 0), (0, 0x04), (0, 0x06), (14, 0), (16, 0), (0, 0x08), (0,
    0x0a), (18, 0), (20, 0), (0, 0x1e), (0, 0x01), (-1, 0), (0, 0x11), (0, 0x16), (0, 0x1a)]

const PLM_VIDEO_CODE_BLOCK_PATTERN: array[126, VlcNode] = [(2, 0), (4, 0), (6, 0), (8, 0), (10,
    0), (12, 0), (14, 0), (16, 0), (18, 0), (20, 0), (22, 0), (24, 0), (26, 0), (0, 60), (28, 0),
    (30, 0), (32, 0), (34, 0), (36, 0), (38, 0), (40, 0), (42, 0), (44, 0), (46, 0), (0, 32), (0,
    16), (0, 8), (0, 4), (48, 0), (50, 0), (52, 0), (54, 0), (56, 0), (58, 0), (60, 0), (62, 0), (
    0, 62), (0, 2), (0, 61), (0, 1), (0, 56), (0, 52), (0, 44), (0, 28), (0, 40), (0, 20), (0,
    48), (0, 12), (64, 0), (66, 0), (68, 0), (70, 0), (72, 0), (74, 0), (76, 0), (78, 0), (80, 0),
    (82, 0), (84, 0), (86, 0), (0, 63), (0, 3), (0, 36), (0, 24), (88, 0), (90, 0), (92, 0), (94,
    0), (96, 0), (98, 0), (100, 0), (102, 0), (104, 0), (106, 0), (108, 0), (110, 0), (112, 0), (
    114, 0), (116, 0), (118, 0), (0, 34), (0, 18), (0, 10), (0, 6), (0, 33), (0, 17), (0, 9), (0,
    5), (-1, 0), (120, 0), (122, 0), (124, 0), (0, 58), (0, 54), (0, 46), (0, 30), (0, 57), (0,
    53), (0, 45), (0, 29), (0, 38), (0, 26), (0, 37), (0, 25), (0, 43), (0, 23), (0, 51), (0, 15),
    (0, 42), (0, 22), (0, 50), (0, 14), (0, 41), (0, 21), (0, 49), (0, 13), (0, 35), (0, 19), (0,
    11), (0, 7), (0, 39), (0, 27), (0, 59), (0, 55), (0, 47), (0, 31)]

const PLM_VIDEO_MOTION: array[68, VlcNode] = [(2, 0), (0, 0), (4, 0), (6, 0), (8, 0), (10, 0), (0,
    1), (0, -1), (12, 0), (14, 0), (0, 2), (0, -2), (16, 0), (18, 0), (0, 3), (0, -3), (20, 0), (
    22, 0), (24, 0), (26, 0), (-1, 0), (28, 0), (30, 0), (32, 0), (34, 0), (36, 0), (0, 4), (0,
    -4), (-1, 0), (38, 0), (40, 0), (42, 0), (0, 7), (0, -7), (0, 6), (0, -6), (0, 5), (0, -5), (
    44, 0), (46, 0), (48, 0), (50, 0), (52, 0), (54, 0), (56, 0), (58, 0), (60, 0), (62, 0), (64,
    0), (66, 0), (0, 10), (0, -10), (0, 9), (0, -9), (0, 8), (0, -8), (0, 16), (0, -16), (0, 15),
    (0, -15), (0, 14), (0, -14), (0, 13), (0, -13), (0, 12), (0, -12), (0, 11), (0, -11)]

const PLM_VIDEO_DCT_SIZE_LUMINANCE: array[18, VlcNode] = [(2, 0), (4, 0), (0, 1), (0, 2), (6, 0),
    (8, 0), (0, 0), (0, 3), (0, 4), (10, 0), (0, 5), (12, 0), (0, 6), (14, 0), (0, 7), (16, 0), (
    0, 8), (-1, 0)]

const PLM_VIDEO_DCT_SIZE_CHROMINANCE: array[18, VlcNode] = [(2, 0), (4, 0), (0, 0), (0, 1), (0,
    2), (6, 0), (0, 3), (8, 0), (0, 4), (10, 0), (0, 5), (12, 0), (0, 6), (14, 0), (0, 7), (16,
    0), (0, 8), (-1, 0)]

const PLM_VIDEO_DCT_COEFF: array[224, VlcNode] = [(2, 0), (0, 0x0001), (4, 0), (6, 0), (8, 0), (
    10, 0), (12, 0), (0, 0x0101), (14, 0), (16, 0), (18, 0), (20, 0), (0, 0x0002), (0, 0x0201), (
    22, 0), (24, 0), (26, 0), (28, 0), (30, 0), (0, 0x0003), (0, 0x0401), (0, 0x0301), (32, 0), (
    0, 0xffff), (34, 0), (36, 0), (0, 0x0701), (0, 0x0601), (0, 0x0102), (0, 0x0501), (38, 0), (
    40, 0), (42, 0), (44, 0), (0, 0x0202), (0, 0x0901), (0, 0x0004), (0, 0x0801), (46, 0), (48,
    0), (50, 0), (52, 0), (54, 0), (56, 0), (58, 0), (60, 0), (0, 0x0d01), (0, 0x0006), (0,
    0x0c01), (0, 0x0b01), (0, 0x0302), (0, 0x0103), (0, 0x0005), (0, 0x0a01), (62, 0), (64, 0), (
    66, 0), (68, 0), (70, 0), (72, 0), (74, 0), (76, 0), (78, 0), (80, 0), (82, 0), (84, 0), (86,
    0), (88, 0), (90, 0), (92, 0), (0, 0x1001), (0, 0x0502), (0, 0x0007), (0, 0x0203), (0,
    0x0104), (0, 0x0f01), (0, 0x0e01), (0, 0x0402), (94, 0), (96, 0), (98, 0), (100, 0), (102, 0),
    (104, 0), (106, 0), (108, 0), (110, 0), (112, 0), (114, 0), (116, 0), (118, 0), (120, 0), (
    122, 0), (124, 0), (-1, 0), (126, 0), (128, 0), (130, 0), (132, 0), (134, 0), (136, 0), (138,
    0), (140, 0), (142, 0), (144, 0), (146, 0), (148, 0), (150, 0), (152, 0), (154, 0), (0,
    0x000b), (0, 0x0802), (0, 0x0403), (0, 0x000a), (0, 0x0204), (0, 0x0702), (0, 0x1501), (0,
    0x1401), (0, 0x0009), (0, 0x1301), (0, 0x1201), (0, 0x0105), (0, 0x0303), (0, 0x0008), (0,
    0x0602), (0, 0x1101), (156, 0), (158, 0), (160, 0), (162, 0), (164, 0), (166, 0), (168, 0), (
    170, 0), (172, 0), (174, 0), (176, 0), (178, 0), (180, 0), (182, 0), (0, 0x0a02), (0, 0x0902),
    (0, 0x0503), (0, 0x0304), (0, 0x0205), (0, 0x0107), (0, 0x0106), (0, 0x000f), (0, 0x000e), (0,
    0x000d), (0, 0x000c), (0, 0x1a01), (0, 0x1901), (0, 0x1801), (0, 0x1701), (0, 0x1601), (184,
    0), (186, 0), (188, 0), (190, 0), (192, 0), (194, 0), (196, 0), (198, 0), (200, 0), (202, 0),
    (204, 0), (206, 0), (0, 0x001f), (0, 0x001e), (0, 0x001d), (0, 0x001c), (0, 0x001b), (0,
    0x001a), (0, 0x0019), (0, 0x0018), (0, 0x0017), (0, 0x0016), (0, 0x0015), (0, 0x0014), (0,
    0x0013), (0, 0x0012), (0, 0x0011), (0, 0x0010), (208, 0), (210, 0), (212, 0), (214, 0), (216,
    0), (218, 0), (220, 0), (222, 0), (0, 0x0028), (0, 0x0027), (0, 0x0026), (0, 0x0025), (0,
    0x0024), (0, 0x0023), (0, 0x0022), (0, 0x0021), (0, 0x0020), (0, 0x010e), (0, 0x010d), (0,
    0x010c), (0, 0x010b), (0, 0x010a), (0, 0x0109), (0, 0x0108), (0, 0x0112), (0, 0x0111), (0,
    0x0110), (0, 0x010f), (0, 0x0603), (0, 0x1002), (0, 0x0f02), (0, 0x0e02), (0, 0x0d02), (0,
    0x0c02), (0, 0x0b02), (0, 0x1f01), (0, 0x1e01), (0, 0x1d01), (0, 0x1c01), (0, 0x1b01)]

func plm_clamp(n: cint): uint8 {.inline.} =
  uint8(min(255'i32, max(0'i32, n)))

proc plm_video_create_with_buffer*(buffer: ptr plm_buffer_t,
    destroyWhenDone: cint): ptr plm_video_t =
  let self = createShared(plm_video_t)
  self.buffer = buffer
  self.destroyBufferWhenDone = destroyWhenDone
  # Attempt to decode the sequence header
  self.startCode = plm_buffer_find_start_code(self.buffer, PLM_START_SEQUENCE)
  if self.startCode != -1:
    discard plm_video_decode_sequence_header(self)
  return self

proc plm_video_destroy*(self: ptr plm_video_t) =
  if self.destroyBufferWhenDone != 0:
    plm_buffer_destroy(self.buffer)
  if self.hasSequenceHeader != 0:
    deallocShared(self.framesData)
  deallocShared(self)

proc plm_video_get_framerate*(self: ptr plm_video_t): float64 =
  return (if plm_video_has_header(self) != 0: self.framerate else: 0.0)

proc plm_video_get_pixel_aspect_ratio*(self: ptr plm_video_t): float64 =
  return (if plm_video_has_header(self) != 0: self.pixelAspectRatio else: 0.0)

proc plm_video_get_width*(self: ptr plm_video_t): cint =
  return (if plm_video_has_header(self) != 0: self.width else: 0)

proc plm_video_get_height*(self: ptr plm_video_t): cint =
  return (if plm_video_has_header(self) != 0: self.height else: 0)

proc plm_video_set_no_delay*(self: ptr plm_video_t, noDelay: cint) =
  self.assumeNoBFrames = noDelay

proc plm_video_get_time*(self: ptr plm_video_t): float64 =
  return self.time

proc plm_video_set_time*(self: ptr plm_video_t, time: float64) =
  self.framesDecoded = cint(self.framerate * time)
  self.time = time

proc plm_video_rewind*(self: ptr plm_video_t) =
  plm_buffer_rewind(self.buffer)
  self.time = 0.0
  self.framesDecoded = 0
  self.hasReferenceFrame = 0
  self.startCode = -1

proc plm_video_has_ended*(self: ptr plm_video_t): cint =
  return plm_buffer_has_ended(self.buffer)

proc plm_video_decode*(self: ptr plm_video_t): ptr plm_frame_t =
  if plm_video_has_header(self) == 0:
    return nil
  var frame: ptr plm_frame_t = nil
  while true:
    if self.startCode != PLM_START_PICTURE:
      self.startCode = plm_buffer_find_start_code(self.buffer, PLM_START_PICTURE)
      if self.startCode == -1:
        # Return the pending reference frame at EOF, including when the
        # last coded picture was a B-frame displayed before it.
        if self.hasReferenceFrame != 0 and self.assumeNoBFrames == 0 and plm_buffer_has_ended(
            self.buffer) != 0:
          self.hasReferenceFrame = 0
          frame = addr(self.frameBackward)
          break
        return nil
    # Make sure we have a full picture in the buffer before attempting to
    # decode it. Sadly, this can only be done by seeking for the start code
    # of the next picture. Also, if we didn't find the start code for the
    # next picture, but the source has ended, we assume that this last
    # picture is in the buffer.
    if plm_buffer_has_start_code(self.buffer, PLM_START_PICTURE) == -1 and plm_buffer_has_ended(
        self.buffer) == 0:
      return nil
    plm_buffer_discard_read_bytes(self.buffer)
    plm_video_decode_picture(self)
    if self.assumeNoBFrames != 0:
      frame = addr(self.frameBackward)
    elif self.pictureType == PLM_VIDEO_PICTURE_TYPE_B:
      frame = addr(self.frameCurrent)
    elif self.hasReferenceFrame != 0:
      frame = addr(self.frameForward)
    else:
      self.hasReferenceFrame = 1
    if frame != nil:
      break
  frame.time = self.time
  inc self.framesDecoded
  self.time = float64(self.framesDecoded) / self.framerate
  return frame

proc plm_video_has_header*(self: ptr plm_video_t): cint =
  if self.hasSequenceHeader != 0:
    return 1
  if self.startCode != PLM_START_SEQUENCE:
    self.startCode = plm_buffer_find_start_code(self.buffer, PLM_START_SEQUENCE)
  if self.startCode == -1:
    return 0
  if plm_video_decode_sequence_header(self) == 0:
    return 0
  return 1

proc plm_video_decode_sequence_header(self: ptr plm_video_t): cint =
  let maxHeaderSize: cint = 64 + 2 * 64 * 8
  if plm_buffer_has(self.buffer, csize_t(maxHeaderSize)) == 0:
    return 0
  self.width = plm_buffer_read(self.buffer, 12)
  self.height = plm_buffer_read(self.buffer, 12)
  if self.width <= 0 or self.height <= 0:
    return 0
  # Get pixel aspect ratio
  let pixelAspectRatioCode = clamp(plm_buffer_read(self.buffer, 4) - 1,
    0, cint(PLM_VIDEO_PIXEL_ASPECT_RATIO.high))
  self.pixelAspectRatio = float64(PLM_VIDEO_PIXEL_ASPECT_RATIO[pixelAspectRatioCode])
  # Get frame rate
  self.framerate = PLM_VIDEO_PICTURE_RATE[plm_buffer_read(self.buffer, 4)]
  # Skip bit_rate, marker, buffer_size and constrained bit
  plm_buffer_skip(self.buffer, csize_t(18 + 1 + 10 + 1))
  # Load custom intra quant matrix?
  if plm_buffer_read(self.buffer, 1) != 0:
    for i in 0 ..< 64:
      let idx: cint = cint(PLM_VIDEO_ZIG_ZAG[i])
      self.intraQuantMatrix[idx] = uint8(plm_buffer_read(self.buffer, 8))
  else:
    self.intraQuantMatrix = PLM_VIDEO_INTRA_QUANT_MATRIX
  # Load custom non intra quant matrix?
  if plm_buffer_read(self.buffer, 1) != 0:
    for i in 0 ..< 64:
      let idx: cint = cint(PLM_VIDEO_ZIG_ZAG[i])
      self.nonIntraQuantMatrix[idx] = uint8(plm_buffer_read(self.buffer, 8))
  else:
    self.nonIntraQuantMatrix = PLM_VIDEO_NON_INTRA_QUANT_MATRIX
  self.mbWidth = (self.width + 15) shr 4
  self.mbHeight = (self.height + 15) shr 4
  self.mbSize = self.mbWidth * self.mbHeight
  self.lumaWidth = self.mbWidth shl 4
  self.lumaHeight = self.mbHeight shl 4
  self.chromaWidth = self.mbWidth shl 3
  self.chromaHeight = self.mbHeight shl 3
  # Allocate one big chunk of data for all 3 frames = 9 planes
  let lumaPlaneSize: csize_t = csize_t(self.lumaWidth * self.lumaHeight)
  let chromaPlaneSize: csize_t = csize_t(self.chromaWidth * self.chromaHeight)
  let frameDataSize: csize_t = (lumaPlaneSize + 2 * chromaPlaneSize)
  self.framesData = cast[ptr uint8](allocShared0(int(frameDataSize * 3)))
  plm_video_init_frame(self, addr(self.frameCurrent), self.framesData)
  plm_video_init_frame(self, addr(self.frameForward), self.framesData + frameDataSize)
  plm_video_init_frame(self, addr(self.frameBackward), self.framesData + frameDataSize * 2)
  self.hasSequenceHeader = 1
  return 1

proc plm_video_init_frame(self: ptr plm_video_t, frame: ptr plm_frame_t, base: ptr uint8) =
  let lumaPlaneSize: csize_t = csize_t(self.lumaWidth * self.lumaHeight)
  let chromaPlaneSize: csize_t = csize_t(self.chromaWidth * self.chromaHeight)
  frame.width = cuint(self.width)
  frame.height = cuint(self.height)
  frame.y.width = cuint(self.lumaWidth)
  frame.y.height = cuint(self.lumaHeight)
  frame.y.data = base
  frame.cr.width = cuint(self.chromaWidth)
  frame.cr.height = cuint(self.chromaHeight)
  frame.cr.data = base + lumaPlaneSize
  frame.cb.width = cuint(self.chromaWidth)
  frame.cb.height = cuint(self.chromaHeight)
  frame.cb.data = base + lumaPlaneSize + chromaPlaneSize

proc plm_video_decode_picture(self: ptr plm_video_t) =
  profileScope("decode picture")
  plm_buffer_skip(self.buffer, 10)
  self.pictureType = plm_buffer_read(self.buffer, 3)
  plm_buffer_skip(self.buffer, 16)
  # D frames or unknown coding type
  if self.pictureType <= 0 or self.pictureType > PLM_VIDEO_PICTURE_TYPE_B:
    return
  # Forward full_px, f_code
  if self.pictureType == PLM_VIDEO_PICTURE_TYPE_PREDICTIVE or self.pictureType == PLM_VIDEO_PICTURE_TYPE_B:
    self.motionForward.fullPx = plm_buffer_read(self.buffer, 1)
    let fCode: cint = plm_buffer_read(self.buffer, 3)
    if fCode == 0:
      # Ignore picture with zero f_code
      return
    self.motionForward.rSize = fCode - 1
  # Backward full_px, f_code
  if self.pictureType == PLM_VIDEO_PICTURE_TYPE_B:
    self.motionBackward.fullPx = plm_buffer_read(self.buffer, 1)
    let fCode: cint = plm_buffer_read(self.buffer, 3)
    if fCode == 0:
      # Ignore picture with zero f_code
      return
    self.motionBackward.rSize = fCode - 1
  let frameTemp: plm_frame_t = self.frameForward
  if self.pictureType == PLM_VIDEO_PICTURE_TYPE_INTRA or self.pictureType == PLM_VIDEO_PICTURE_TYPE_PREDICTIVE:
    self.frameForward = self.frameBackward
  # Find first slice start code; skip extension and user data
  while true:
    self.startCode = plm_buffer_next_start_code(self.buffer)
    if not (self.startCode == PLM_START_EXTENSION or self.startCode == PLM_START_USER_DATA):
      break
  # Decode all slices
  while self.startCode >= PLM_START_SLICE_FIRST and self.startCode <= PLM_START_SLICE_LAST:
    plm_video_decode_slice(self, self.startCode and 0x000000FF)
    if self.macroblockAddress >= self.mbSize - 1:
      break
    self.startCode = plm_buffer_next_start_code(self.buffer)
  # If this is a reference picture rotate the prediction pointers
  if self.pictureType == PLM_VIDEO_PICTURE_TYPE_INTRA or self.pictureType == PLM_VIDEO_PICTURE_TYPE_PREDICTIVE:
    self.frameBackward = self.frameCurrent
    self.frameCurrent = frameTemp

proc plm_video_decode_slice(self: ptr plm_video_t, slice: cint) =
  self.sliceBegin = 1
  self.macroblockAddress = (slice - 1) * self.mbWidth - 1
  # Reset motion vectors and DC predictors
  self.motionForward.h = 0
  self.motionBackward.h = self.motionForward.h
  self.motionForward.v = 0
  self.motionBackward.v = self.motionForward.v
  self.dcPredictor = [128'i32, 128, 128]
  self.quantizerScale = plm_buffer_read(self.buffer, 5)
  # Skip extra
  while plm_buffer_read(self.buffer, 1) != 0:
    plm_buffer_skip(self.buffer, 8)
  while true:
    plm_video_decode_macroblock(self)
    if not (self.macroblockAddress < self.mbSize - 1 and plm_buffer_peek_non_zero(self.buffer,
        23) != 0):
      break

proc plm_video_decode_macroblock(self: ptr plm_video_t) =
  profileScope("decode macroblock", detail = true)
  # Decode increment
  var increment: cint = 0
  var t: cint = readVlc(self.buffer, PLM_VIDEO_MACROBLOCK_ADDRESS_INCREMENT)
  while t == 34:
    # macroblock_stuffing
    t = readVlc(self.buffer, PLM_VIDEO_MACROBLOCK_ADDRESS_INCREMENT)
  while t == 35:
    # macroblock_escape
    increment += 33
    t = readVlc(self.buffer, PLM_VIDEO_MACROBLOCK_ADDRESS_INCREMENT)
  increment += t
  # Process any skipped macroblocks
  if self.sliceBegin != 0:
    # The first increment of each slice is relative to beginning of the
    # previous row, not the previous macroblock
    self.sliceBegin = 0
    self.macroblockAddress += increment
  else:
    if self.macroblockAddress + increment >= self.mbSize:
      return
    if increment > 1:
      # Skipped macroblocks reset DC predictors
      self.dcPredictor = [128'i32, 128, 128]
      # Skipped macroblocks in P-pictures reset motion vectors
      if self.pictureType == PLM_VIDEO_PICTURE_TYPE_PREDICTIVE:
        self.motionForward.h = 0
        self.motionForward.v = 0
    # Predict skipped macroblocks
    while increment > 1:
      inc self.macroblockAddress
      self.mbRow = self.macroblockAddress div self.mbWidth
      self.mbCol = self.macroblockAddress mod self.mbWidth
      plm_video_predict_macroblock(self)
      dec increment
    inc self.macroblockAddress
  self.mbRow = self.macroblockAddress div self.mbWidth
  self.mbCol = self.macroblockAddress mod self.mbWidth
  if self.macroblockAddress < 0 or self.macroblockAddress >= self.mbSize:
    return
  # Process the current macroblock
  self.macroblockType =
    case self.pictureType
    of PLM_VIDEO_PICTURE_TYPE_INTRA: readVlc(self.buffer, PLM_VIDEO_MACROBLOCK_TYPE_INTRA)
    of PLM_VIDEO_PICTURE_TYPE_PREDICTIVE: readVlc(self.buffer, PLM_VIDEO_MACROBLOCK_TYPE_PREDICTIVE)
    else: readVlc(self.buffer, PLM_VIDEO_MACROBLOCK_TYPE_B)
  self.macroblockIntra = (self.macroblockType and 0x01)
  self.motionForward.isSet = (self.macroblockType and 0x08)
  self.motionBackward.isSet = (self.macroblockType and 0x04)
  # Quantizer scale
  if (self.macroblockType and 0x10) != 0:
    self.quantizerScale = plm_buffer_read(self.buffer, 5)
  if self.macroblockIntra != 0:
    # Intra-coded macroblocks reset motion vectors
    self.motionForward.h = 0
    self.motionBackward.h = self.motionForward.h
    self.motionForward.v = 0
    self.motionBackward.v = self.motionForward.v
  else:
    # Non-intra macroblocks reset DC predictors
    self.dcPredictor = [128'i32, 128, 128]
    plm_video_decode_motion_vectors(self)
    plm_video_predict_macroblock(self)
  # Decode blocks
  let cbp: cint = (if (self.macroblockType and 0x02) != 0: readVlc(self.buffer,
      PLM_VIDEO_CODE_BLOCK_PATTERN) else: (if self.macroblockIntra != 0: 0x3f else: 0))
  var blockIndex: cint = 0
  var mask: cint = 0x20
  while blockIndex < 6:
    if (cbp and mask) != 0:
      plm_video_decode_block(self, blockIndex)
    mask = mask shr 1
    inc blockIndex

proc plm_video_decode_motion_vectors(self: ptr plm_video_t) =
  # Forward
  if self.motionForward.isSet != 0:
    let rSize: cint = self.motionForward.rSize
    self.motionForward.h = plm_video_decode_motion_vector(self, rSize, self.motionForward.h)
    self.motionForward.v = plm_video_decode_motion_vector(self, rSize, self.motionForward.v)
  elif self.pictureType == PLM_VIDEO_PICTURE_TYPE_PREDICTIVE:
    # No motion information in P-picture, reset vectors
    self.motionForward.h = 0
    self.motionForward.v = 0
  if self.motionBackward.isSet != 0:
    let rSize: cint = self.motionBackward.rSize
    self.motionBackward.h = plm_video_decode_motion_vector(self, rSize, self.motionBackward.h)
    self.motionBackward.v = plm_video_decode_motion_vector(self, rSize, self.motionBackward.v)

proc plm_video_decode_motion_vector(self: ptr plm_video_t, rSize: cint, motion: cint): cint =
  var motion = motion
  let fscale: cint = 1'i32 shl rSize
  let mCode: cint = readVlc(self.buffer, PLM_VIDEO_MOTION)
  var r: cint = 0
  var d: cint
  if mCode != 0 and fscale != 1:
    r = plm_buffer_read(self.buffer, rSize)
    d = ((abs(mCode) - 1) shl rSize) + r + 1
    if mCode < 0:
      d = -d
  else:
    d = mCode
  motion += d
  if motion > (fscale shl 4) - 1:
    motion -= fscale shl 5
  elif motion < -(fscale shl 4):
    motion += fscale shl 5
  return motion

proc plm_video_predict_macroblock(self: ptr plm_video_t) =
  profileScope("motion compensation", detail = true)
  var fwH: cint = self.motionForward.h
  var fwV: cint = self.motionForward.v
  if self.motionForward.fullPx != 0:
    fwH = fwH shl 1
    fwV = fwV shl 1
  if self.pictureType == PLM_VIDEO_PICTURE_TYPE_B:
    var bwH: cint = self.motionBackward.h
    var bwV: cint = self.motionBackward.v
    if self.motionBackward.fullPx != 0:
      bwH = bwH shl 1
      bwV = bwV shl 1
    if self.motionForward.isSet != 0:
      plm_video_copy_macroblock(self, addr(self.frameForward), fwH, fwV)
      if self.motionBackward.isSet != 0:
        plm_video_interpolate_macroblock(self, addr(self.frameBackward), bwH, bwV)
    else:
      plm_video_copy_macroblock(self, addr(self.frameBackward), bwH, bwV)
  else:
    plm_video_copy_macroblock(self, addr(self.frameForward), fwH, fwV)

proc plm_video_copy_macroblock(self: ptr plm_video_t, s: ptr plm_frame_t, motionH: cint,
    motionV: cint) =
  let d = addr(self.frameCurrent)
  plm_video_process_macroblock(self, s.y.data, d.y.data, motionH, motionV, 16, 0)
  plm_video_process_macroblock(self, s.cr.data, d.cr.data, motionH div 2, motionV div 2, 8, 0)
  plm_video_process_macroblock(self, s.cb.data, d.cb.data, motionH div 2, motionV div 2, 8, 0)

proc plm_video_interpolate_macroblock(self: ptr plm_video_t, s: ptr plm_frame_t, motionH: cint,
    motionV: cint) =
  let d = addr(self.frameCurrent)
  plm_video_process_macroblock(self, s.y.data, d.y.data, motionH, motionV, 16, 1)
  plm_video_process_macroblock(self, s.cr.data, d.cr.data, motionH div 2, motionV div 2, 8, 1)
  plm_video_process_macroblock(self, s.cb.data, d.cb.data, motionH div 2, motionV div 2, 8, 1)

proc plm_video_process_macroblock(self: ptr plm_video_t, s: ptr uint8, d: ptr uint8,
    motionH: cint, motionV: cint, blockSize: cint, interpolate: cint) =
  let
    width = self.mbWidth * blockSize
    height = self.mbHeight * blockSize
    dstX = self.mbCol * blockSize
    dstY = self.mbRow * blockSize
    srcX = dstX + (motionH shr 1)
    srcY = dstY + (motionV shr 1)
    halfX = motionH and 1
    halfY = motionV and 1
  if dstX < 0 or dstY < 0 or dstX + blockSize > width or dstY + blockSize > height:
    return
  if srcX < 0 or srcY < 0 or srcX + blockSize + halfX > width or srcY + blockSize + halfY > height:
    return
  # Both rectangles, including half-pixel neighbors, fit the padded planes.
  {.push checks: off.}
  for row in 0 ..< blockSize:
    let
      sourceRow = (srcY + row) * width + srcX
      destRow = (dstY + row) * width + dstX
    if halfX == 0 and halfY == 0 and interpolate == 0:
      copyMem(addr d[destRow], addr s[sourceRow], int(blockSize))
      continue
    for col in 0 ..< blockSize:
      let
        si = sourceRow + col
        di = destRow + col
      var pixel = int(s[si])
      if halfX != 0 and halfY != 0:
        pixel = (pixel + int(s[si + 1]) + int(s[si + width]) + int(s[si + width + 1]) + 2) shr 2
      elif halfX != 0:
        pixel = (pixel + int(s[si + 1]) + 1) shr 1
      elif halfY != 0:
        pixel = (pixel + int(s[si + width]) + 1) shr 1
      if interpolate != 0:
        pixel = (pixel + int(d[di]) + 1) shr 1
      d[di] = uint8(pixel)
  {.pop.}

proc plm_video_decode_block(self: ptr plm_video_t, blockIndex: cint) =
  profileScope("decode block", detail = true)
  var n: cint = 0
  var quantMatrix: ptr uint8
  # Decode DC coefficient of intra-coded blocks
  if self.macroblockIntra != 0:
    var predictor: cint
    var dctSize: cint
    # DC prediction
    let planeIndex: cint = (if blockIndex > 3: blockIndex - 3 else: 0)
    predictor = self.dcPredictor[planeIndex]
    dctSize = if planeIndex == 0: readVlc(self.buffer, PLM_VIDEO_DCT_SIZE_LUMINANCE)
              else: readVlc(self.buffer, PLM_VIDEO_DCT_SIZE_CHROMINANCE)
    # Read DC coeff
    if dctSize > 0:
      let differential: cint = plm_buffer_read(self.buffer, dctSize)
      if (differential and (1 shl (dctSize - 1))) != 0:
        self.blockData[0] = predictor + differential
      else:
        self.blockData[0] = predictor + (-(1'i32 shl dctSize) or (differential + 1))
    else:
      self.blockData[0] = predictor
    # Save predictor value
    self.dcPredictor[planeIndex] = self.blockData[0]
    # Dequantize + premultiply
    self.blockData[0] = self.blockData[0] shl (3 + 5)
    quantMatrix = addr(self.intraQuantMatrix[0])
    n = 1
  else:
    quantMatrix = addr(self.nonIntraQuantMatrix[0])
  # Decode AC coefficients (+DC for non-intra)
  var level: cint = 0
  while true:
    var run: cint = 0
    let coeff = readVlc(self.buffer, PLM_VIDEO_DCT_COEFF)
    if coeff == 0x0001 and n > 0 and plm_buffer_read(self.buffer, 1) == 0:
      # end_of_block
      break
    if coeff == 0xffff:
      # escape
      run = plm_buffer_read(self.buffer, 6)
      level = plm_buffer_read(self.buffer, 8)
      if level == 0:
        level = plm_buffer_read(self.buffer, 8)
      elif level == 128:
        level = plm_buffer_read(self.buffer, 8) - 256
      elif level > 128:
        level = level - 256
    else:
      run = coeff shr 8
      level = coeff and 0xff
      if plm_buffer_read(self.buffer, 1) != 0:
        level = -level
    n += run
    if n < 0 or n >= 64:
      return
    let deZigZagged: cint = cint(PLM_VIDEO_ZIG_ZAG[n])
    inc n
    # Dequantize, oddify, clip
    level = level shl 1
    if self.macroblockIntra == 0:
      level += (if level < 0: -1 else: 1)
    level = (level * self.quantizerScale * cint(quantMatrix[deZigZagged])) shr 4
    if (level and 1) == 0:
      level -= (if level > 0: 1 else: -1)
    if level > 2047:
      level = 2047
    elif level < -2048:
      level = -2048
    # Save premultiplied coefficient
    self.blockData[deZigZagged] = level * cint(PLM_VIDEO_PREMULTIPLIER_MATRIX[deZigZagged])
  # Move block to its place
  var d: ptr uint8
  var dw: cint
  var di: cint
  if blockIndex < 4:
    d = self.frameCurrent.y.data
    dw = self.lumaWidth
    di = (self.mbRow * self.lumaWidth + self.mbCol) shl 4
    if (blockIndex and 1) != 0:
      di += 8
    if (blockIndex and 2) != 0:
      di += self.lumaWidth shl 3
  else:
    d = (if blockIndex == 4: self.frameCurrent.cb.data else: self.frameCurrent.cr.data)
    dw = self.chromaWidth
    di = ((self.mbRow * self.lumaWidth) shl 2) + (self.mbCol shl 3)
  let dcOnly = n == 1
  if dcOnly:
    self.blockData[0] = (self.blockData[0] + 128) shr 8
  else:
    plm_video_idct(self.blockData)
  # The caller validated the macroblock address. This 8x8 tile fits its
  # padded plane; residuals after the IDCT's final shift fit in 24 bits.
  {.push checks: off.}
  for row in 0 ..< 8:
    for col in 0 ..< 8:
      let i = di + row * dw + col
      var value = if dcOnly: self.blockData[0] else: self.blockData[row * 8 + col]
      if self.macroblockIntra == 0:
        value += cint(d[i])
      d[i] = plm_clamp(value)
  {.pop.}
  reset(self.blockData)

# AC coefficients are clipped to [-2048, 2047] and premultiplied by at
# most 62. An 8-point butterfly grows by less than 25x, so its first-pass
# outputs fit in 3.2 million and its second-pass outputs in 80 million.
# Splitting 473, 196 and 362 into multiples of 256 plus small remainders
# bounds the largest product by 4 * 3.2 million * 106, within int32.
{.push checks: off.}
proc plm_video_idct(coefficients: var array[64, cint]) =
  profileScope("video IDCT", detail = true)
  # Whole DC units add equally to every output. Only the low eight bits
  # participate in rounding, even when the predictor is negative.
  let dc = coefficients[0] shr 8
  coefficients[0] = coefficients[0] and 255

  template transform(column: static bool, base: int) =
    template get(k: static int): cint =
      when column: coefficients[base + 8 * k]
      else: coefficients[base + k]
    template put(k: static int, value: cint) =
      when column: coefficients[base + 8 * k] = value
      else: coefficients[base + k] = dc + ((value + 128) shr 8)
    let
      b1 = get(4)
      b3 = get(2) + get(6)
      b4 = get(5) - get(3)
      tmp1 = get(1) + get(7)
      tmp2 = get(3) + get(5)
      b6 = get(1) - get(7)
      b7 = tmp1 + tmp2
      x4 = 2 * b6 - b4 + ((60 * b4 - 39 * b6 + 128) shr 8) - b7
      odd = tmp1 - tmp2
      x0 = x4 - (odd + ((106 * odd + 128) shr 8))
      x1 = get(0) - b1
      even = get(2) - get(6)
      x2 = even + ((106 * even + 128) shr 8) - b3
      x3 = get(0) + b1
      y3 = x1 + x2
      y4 = x3 + b3
      y5 = x1 - x2
      y6 = x3 - b3
      y7 = -x0 - (2 * b4 + b6 + ((128 - 39 * b4 - 60 * b6) shr 8))
    put(0, b7 + y4)
    put(1, x4 + y3)
    put(2, y5 - x0)
    put(3, y6 - y7)
    put(4, y6 + y7)
    put(5, x0 + y5)
    put(6, y3 - x4)
    put(7, y4 - b7)

  for col in 0..<8:
    transform(true, col)
  for row in 0..<8:
    transform(false, 8 * row)
{.pop.}
