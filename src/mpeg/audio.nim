proc plm_audio_find_frame_sync(self: ptr plm_audio_t): cint
proc plm_audio_decode_header(self: ptr plm_audio_t): cint
proc plm_audio_decode_frame(self: ptr plm_audio_t)
proc plm_audio_read_allocation(self: ptr plm_audio_t, sb: cint,
    tab3: cint): ptr plm_quantizer_spec_t
proc plm_audio_read_samples(self: ptr plm_audio_t, ch: cint, sb: cint, part: cint)
proc plm_audio_idct36(s: array[32, array[3, cint]], ss: int, d: var array[1024, float32], dp: cint)

const PLM_AUDIO_FRAME_SYNC: cint = 0x7ff

const PLM_AUDIO_MPEG_1: cint = 0x3

const PLM_AUDIO_LAYER_II: cint = 0x2

const PLM_AUDIO_MODE_JOINT_STEREO: cint = 0x1

const PLM_AUDIO_MODE_MONO: cint = 0x3

const PLM_AUDIO_SAMPLE_RATE: array[8, uint16] = [44100, 48000, 32000, 0, 22050, 24000, 16000, 0]

const PLM_AUDIO_BIT_RATE: array[28, int16] = [32, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224,
    256, 320, 384, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160]

const scaleFactors = block:
  const bases = [0x02000000'i32, 0x01965FEA, 0x01428A30]
  var factors: array[64, cint]
  for i in 0..<63: # Index 63 represents silence.
    let shift = i div 3
    factors[i] = (bases[i mod 3] + ((1'i32 shl shift) shr 1)) shr shift
  factors

const PLM_AUDIO_SYNTHESIS_WINDOW: array[512, float32] = [0.0'f32, -0.5'f32, -0.5'f32, -0.5'f32,
    -0.5'f32, -0.5'f32, -0.5'f32, -1.0'f32, -1.0'f32, -1.0'f32, -1.0'f32, -1.5'f32, -1.5'f32,
    -2.0'f32, -2.0'f32, -2.5'f32, -2.5'f32, -3.0'f32, -3.5'f32, -3.5'f32, -4.0'f32, -4.5'f32,
    -5.0'f32, -5.5'f32, -6.5'f32, -7.0'f32, -8.0'f32, -8.5'f32, -9.5'f32, -10.5'f32, -12.0'f32,
    -13.0'f32, -14.5'f32, -15.5'f32, -17.5'f32, -19.0'f32, -20.5'f32, -22.5'f32, -24.5'f32,
    -26.5'f32, -29.0'f32, -31.5'f32, -34.0'f32, -36.5'f32, -39.5'f32, -42.5'f32, -45.5'f32,
    -48.5'f32, -52.0'f32, -55.5'f32, -58.5'f32, -62.5'f32, -66.0'f32, -69.5'f32, -73.5'f32,
    -77.0'f32, -80.5'f32, -84.5'f32, -88.0'f32, -91.5'f32, -95.0'f32, -98.0'f32, -101.0'f32,
    -104.0'f32, 106.5'f32, 109.0'f32, 111.0'f32, 112.5'f32, 113.5'f32, 114.0'f32, 114.0'f32,
    113.5'f32, 112.0'f32, 110.5'f32, 107.5'f32, 104.0'f32, 100.0'f32, 94.5'f32, 88.5'f32,
    81.5'f32, 73.0'f32, 63.5'f32, 53.0'f32, 41.5'f32, 28.5'f32, 14.5'f32, -1.0'f32, -18.0'f32,
    -36.0'f32, -55.5'f32, -76.5'f32, -98.5'f32, -122.0'f32, -147.0'f32, -173.5'f32, -200.5'f32,
    -229.5'f32, -259.5'f32, -290.5'f32, -322.5'f32, -355.5'f32, -389.5'f32, -424.0'f32,
    -459.5'f32, -495.5'f32, -532.0'f32, -568.5'f32, -605.0'f32, -641.5'f32, -678.0'f32,
    -714.0'f32, -749.0'f32, -783.5'f32, -817.0'f32, -849.0'f32, -879.5'f32, -908.5'f32,
    -935.0'f32, -959.5'f32, -981.0'f32, -1000.5'f32, -1016.0'f32, -1028.5'f32, -1037.5'f32,
    -1042.5'f32, -1043.5'f32, -1040.0'f32, -1031.5'f32, 1018.5'f32, 1000.0'f32, 976.0'f32,
    946.5'f32, 911.0'f32, 869.5'f32, 822.0'f32, 767.5'f32, 707.0'f32, 640.0'f32, 565.5'f32,
    485.0'f32, 397.0'f32, 302.5'f32, 201.0'f32, 92.5'f32, -22.5'f32, -144.0'f32, -272.5'f32,
    -407.0'f32, -547.5'f32, -694.0'f32, -846.0'f32, -1003.0'f32, -1165.0'f32, -1331.5'f32,
    -1502.0'f32, -1675.5'f32, -1852.5'f32, -2031.5'f32, -2212.5'f32, -2394.0'f32, -2576.5'f32,
    -2758.5'f32, -2939.5'f32, -3118.5'f32, -3294.5'f32, -3467.5'f32, -3635.5'f32, -3798.5'f32,
    -3955.0'f32, -4104.5'f32, -4245.5'f32, -4377.5'f32, -4499.0'f32, -4609.5'f32, -4708.0'f32,
    -4792.5'f32, -4863.5'f32, -4919.0'f32, -4958.0'f32, -4979.5'f32, -4983.0'f32, -4967.5'f32,
    -4931.5'f32, -4875.0'f32, -4796.0'f32, -4694.5'f32, -4569.5'f32, -4420.0'f32, -4246.0'f32,
    -4046.0'f32, -3820.0'f32, -3567.0'f32, 3287.0'f32, 2979.5'f32, 2644.0'f32, 2280.5'f32,
    1888.0'f32, 1467.5'f32, 1018.5'f32, 541.0'f32, 35.0'f32, -499.0'f32, -1061.0'f32, -1650.0'f32,
    -2266.5'f32, -2909.0'f32, -3577.0'f32, -4270.0'f32, -4987.5'f32, -5727.5'f32, -6490.0'f32,
    -7274.0'f32, -8077.5'f32, -8899.5'f32, -9739.0'f32, -10594.5'f32, -11464.5'f32, -12347.0'f32,
    -13241.0'f32, -14144.5'f32, -15056.0'f32, -15973.5'f32, -16895.5'f32, -17820.0'f32,
    -18744.5'f32, -19668.0'f32, -20588.0'f32, -21503.0'f32, -22410.5'f32, -23308.5'f32,
    -24195.0'f32, -25068.5'f32, -25926.5'f32, -26767.0'f32, -27589.0'f32, -28389.0'f32,
    -29166.5'f32, -29919.0'f32, -30644.5'f32, -31342.0'f32, -32009.5'f32, -32645.0'f32,
    -33247.0'f32, -33814.5'f32, -34346.0'f32, -34839.5'f32, -35295.0'f32, -35710.0'f32,
    -36084.5'f32, -36417.5'f32, -36707.5'f32, -36954.0'f32, -37156.5'f32, -37315.0'f32,
    -37428.0'f32, -37496.0'f32, 37519.0'f32, 37496.0'f32, 37428.0'f32, 37315.0'f32, 37156.5'f32,
    36954.0'f32, 36707.5'f32, 36417.5'f32, 36084.5'f32, 35710.0'f32, 35295.0'f32, 34839.5'f32,
    34346.0'f32, 33814.5'f32, 33247.0'f32, 32645.0'f32, 32009.5'f32, 31342.0'f32, 30644.5'f32,
    29919.0'f32, 29166.5'f32, 28389.0'f32, 27589.0'f32, 26767.0'f32, 25926.5'f32, 25068.5'f32,
    24195.0'f32, 23308.5'f32, 22410.5'f32, 21503.0'f32, 20588.0'f32, 19668.0'f32, 18744.5'f32,
    17820.0'f32, 16895.5'f32, 15973.5'f32, 15056.0'f32, 14144.5'f32, 13241.0'f32, 12347.0'f32,
    11464.5'f32, 10594.5'f32, 9739.0'f32, 8899.5'f32, 8077.5'f32, 7274.0'f32, 6490.0'f32,
    5727.5'f32, 4987.5'f32, 4270.0'f32, 3577.0'f32, 2909.0'f32, 2266.5'f32, 1650.0'f32,
    1061.0'f32, 499.0'f32, -35.0'f32, -541.0'f32, -1018.5'f32, -1467.5'f32, -1888.0'f32,
    -2280.5'f32, -2644.0'f32, -2979.5'f32, 3287.0'f32, 3567.0'f32, 3820.0'f32, 4046.0'f32,
    4246.0'f32, 4420.0'f32, 4569.5'f32, 4694.5'f32, 4796.0'f32, 4875.0'f32, 4931.5'f32,
    4967.5'f32, 4983.0'f32, 4979.5'f32, 4958.0'f32, 4919.0'f32, 4863.5'f32, 4792.5'f32,
    4708.0'f32, 4609.5'f32, 4499.0'f32, 4377.5'f32, 4245.5'f32, 4104.5'f32, 3955.0'f32,
    3798.5'f32, 3635.5'f32, 3467.5'f32, 3294.5'f32, 3118.5'f32, 2939.5'f32, 2758.5'f32,
    2576.5'f32, 2394.0'f32, 2212.5'f32, 2031.5'f32, 1852.5'f32, 1675.5'f32, 1502.0'f32,
    1331.5'f32, 1165.0'f32, 1003.0'f32, 846.0'f32, 694.0'f32, 547.5'f32, 407.0'f32, 272.5'f32,
    144.0'f32, 22.5'f32, -92.5'f32, -201.0'f32, -302.5'f32, -397.0'f32, -485.0'f32, -565.5'f32,
    -640.0'f32, -707.0'f32, -767.5'f32, -822.0'f32, -869.5'f32, -911.0'f32, -946.5'f32,
    -976.0'f32, -1000.0'f32, 1018.5'f32, 1031.5'f32, 1040.0'f32, 1043.5'f32, 1042.5'f32,
    1037.5'f32, 1028.5'f32, 1016.0'f32, 1000.5'f32, 981.0'f32, 959.5'f32, 935.0'f32, 908.5'f32,
    879.5'f32, 849.0'f32, 817.0'f32, 783.5'f32, 749.0'f32, 714.0'f32, 678.0'f32, 641.5'f32,
    605.0'f32, 568.5'f32, 532.0'f32, 495.5'f32, 459.5'f32, 424.0'f32, 389.5'f32, 355.5'f32,
    322.5'f32, 290.5'f32, 259.5'f32, 229.5'f32, 200.5'f32, 173.5'f32, 147.0'f32, 122.0'f32,
    98.5'f32, 76.5'f32, 55.5'f32, 36.0'f32, 18.0'f32, 1.0'f32, -14.5'f32, -28.5'f32, -41.5'f32,
    -53.0'f32, -63.5'f32, -73.0'f32, -81.5'f32, -88.5'f32, -94.5'f32, -100.0'f32, -104.0'f32,
    -107.5'f32, -110.5'f32, -112.0'f32, -113.5'f32, -114.0'f32, -114.0'f32, -113.5'f32,
    -112.5'f32, -111.0'f32, -109.0'f32, 106.5'f32, 104.0'f32, 101.0'f32, 98.0'f32, 95.0'f32,
    91.5'f32, 88.0'f32, 84.5'f32, 80.5'f32, 77.0'f32, 73.5'f32, 69.5'f32, 66.0'f32, 62.5'f32,
    58.5'f32, 55.5'f32, 52.0'f32, 48.5'f32, 45.5'f32, 42.5'f32, 39.5'f32, 36.5'f32, 34.0'f32,
    31.5'f32, 29.0'f32, 26.5'f32, 24.5'f32, 22.5'f32, 20.5'f32, 19.0'f32, 17.5'f32, 15.5'f32,
    14.5'f32, 13.0'f32, 12.0'f32, 10.5'f32, 9.5'f32, 8.5'f32, 8.0'f32, 7.0'f32, 6.5'f32, 5.5'f32,
    5.0'f32, 4.5'f32, 4.0'f32, 3.5'f32, 3.5'f32, 3.0'f32, 2.5'f32, 2.5'f32, 2.0'f32, 2.0'f32,
    1.5'f32, 1.5'f32, 1.0'f32, 1.0'f32, 1.0'f32, 1.0'f32, 0.5'f32, 0.5'f32, 0.5'f32, 0.5'f32,
    0.5'f32, 0.5'f32]

const PLM_AUDIO_QUANT_LUT_STEP_1: array[2, array[16, uint8]] = [[0, 0, 1, 1, 1, 2, 2, 2, 2, 2, 2,
    2, 2, 2, 0, 0], [0, 0, 0, 0, 0, 0, 1, 1, 1, 2, 2, 2, 2, 2, 0, 0]]

const QUANT_LUT_STEP_2: array[3, array[3, uint8]] = [[8, 8, 12], [uint8((27 or 64)), uint8((27 or
    64)), uint8((27 or 64))], [uint8((30 or 64)), uint8((27 or 64)), uint8((30 or 64))]]

const PLM_AUDIO_QUANT_LUT_STEP_3: array[3, array[32, uint8]] = [[0x44, 0x44, 0x34, 0x34, 0x34,
    0x34, 0x34, 0x34, 0x34, 0x34, 0x34, 0x34, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0], [0x43, 0x43, 0x43, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x31, 0x31, 0x31,
    0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20,
    0x20, 0, 0], [0x45, 0x45, 0x45, 0x45, 0x34, 0x34, 0x34, 0x34, 0x34, 0x34, 0x34, 0x24, 0x24,
    0x24, 0x24, 0x24, 0x24, 0x24, 0x24, 0x24, 0x24, 0x24, 0x24, 0x24, 0x24, 0x24, 0x24, 0x24,
    0x24, 0x24, 0, 0]]

const PLM_AUDIO_QUANT_LUT_STEP_4: array[6, array[16, uint8]] = [[0, 1, 2, 17, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0], [0, 1, 2, 3, 4, 5, 6, 17, 0, 0, 0, 0, 0, 0, 0, 0], [0, 1, 2, 3, 4, 5, 6, 7, 8,
    9, 10, 11, 12, 13, 14, 17], [0, 1, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17], [0, 1,
    2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 17], [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
    13, 14, 15]]

func quantizer(levels, bits: int, grouped: bool = false): plm_quantizer_spec_t =
  plm_quantizer_spec_t(levels: uint16(levels), bits: uint8(bits),
    group: uint8(grouped), scale: uint16(65536 div (levels + 1)))

let PLM_AUDIO_QUANT_TAB = [
  quantizer(3, 5, true), quantizer(5, 7, true), quantizer(7, 3),
  quantizer(9, 10, true), quantizer(15, 4), quantizer(31, 5), quantizer(63, 6),
  quantizer(127, 7), quantizer(255, 8), quantizer(511, 9), quantizer(1023, 10),
  quantizer(2047, 11), quantizer(4095, 12), quantizer(8191, 13),
  quantizer(16383, 14), quantizer(32767, 15), quantizer(65535, 16)]

proc plm_audio_create_with_buffer*(buffer: ptr plm_buffer_t,
    destroyWhenDone: cint): ptr plm_audio_t =
  let self = createShared(plm_audio_t)
  self.samples.count = PlmAudioSamplesPerFrame
  self.buffer = buffer
  self.destroyBufferWhenDone = destroyWhenDone
  self.samplerateIndex = 3
  # Attempt to decode first header
  self.nextFrameDataSize = plm_audio_decode_header(self)
  return self

proc plm_audio_destroy*(self: ptr plm_audio_t) =
  if self.destroyBufferWhenDone != 0:
    plm_buffer_destroy(self.buffer)
  deallocShared(self)

proc plm_audio_has_header*(self: ptr plm_audio_t): cint =
  if self.hasHeader != 0:
    return 1
  self.nextFrameDataSize = plm_audio_decode_header(self)
  return self.hasHeader

proc plm_audio_get_samplerate*(self: ptr plm_audio_t): cint =
  return (if plm_audio_has_header(self) != 0: cint(PLM_AUDIO_SAMPLE_RATE[
      self.samplerateIndex]) else: 0)

proc plm_audio_get_time*(self: ptr plm_audio_t): float64 =
  return self.time

proc plm_audio_set_time*(self: ptr plm_audio_t, time: float64) =
  self.samplesDecoded = cint(time * float64(PLM_AUDIO_SAMPLE_RATE[self.samplerateIndex]))
  self.time = time

proc plm_audio_rewind*(self: ptr plm_audio_t) =
  plm_buffer_rewind(self.buffer)
  self.time = 0.0
  self.samplesDecoded = 0
  self.nextFrameDataSize = 0

proc plm_audio_has_ended*(self: ptr plm_audio_t): cint =
  return plm_buffer_has_ended(self.buffer)

proc plm_audio_decode*(self: ptr plm_audio_t): ptr plm_samples_t =
  # Do we have at least enough information to decode the frame header?
  if self.nextFrameDataSize == 0:
    if plm_buffer_has(self.buffer, 48) == 0:
      return nil
    self.nextFrameDataSize = plm_audio_decode_header(self)
  if self.nextFrameDataSize == 0 or plm_buffer_has(self.buffer, csize_t(
      self.nextFrameDataSize shl 3)) == 0:
    return nil
  plm_audio_decode_frame(self)
  self.nextFrameDataSize = 0
  self.samples.time = self.time
  self.samplesDecoded += PlmAudioSamplesPerFrame
  self.time = float64(self.samplesDecoded) / float64(PLM_AUDIO_SAMPLE_RATE[self.samplerateIndex])
  return addr(self.samples)

proc plm_audio_find_frame_sync(self: ptr plm_audio_t): cint =
  var i: csize_t
  i = self.buffer.bitIndex shr 3
  while i + 1 < self.buffer.length:
    if cint(self.buffer.bytes[i]) == 0xFF and (cint(self.buffer.bytes[i + 1]) and 0xFE) == 0xFC:
      self.buffer.bitIndex = ((i + 1) shl 3) + 3
      return 1
    inc i
  self.buffer.bitIndex = self.buffer.length shl 3
  return 0

proc plm_audio_decode_header(self: ptr plm_audio_t): cint =
  if plm_buffer_has(self.buffer, 48) == 0:
    return 0
  discard plm_buffer_skip_bytes(self.buffer, 0x00)
  let sync: cint = plm_buffer_read(self.buffer, 11)
  if sync != PLM_AUDIO_FRAME_SYNC and plm_audio_find_frame_sync(self) == 0:
    return 0
  self.version = plm_buffer_read(self.buffer, 2)
  self.layer = plm_buffer_read(self.buffer, 2)
  let hasCRC: cint = cint(plm_buffer_read(self.buffer, 1) == 0)
  if self.version != PLM_AUDIO_MPEG_1 or self.layer != PLM_AUDIO_LAYER_II:
    return 0
  let bitrateIndex: cint = plm_buffer_read(self.buffer, 4) - 1
  if bitrateIndex notin 0 .. 13:
    return 0
  let samplerateIndex: cint = plm_buffer_read(self.buffer, 2)
  if samplerateIndex == 3:
    return 0
  let padding: cint = plm_buffer_read(self.buffer, 1)
  plm_buffer_skip(self.buffer, 1)
  let mode: cint = plm_buffer_read(self.buffer, 2)
  # If we already have a header, make sure the samplerate, bitrate and mode
  # are still the same, otherwise we might have missed sync.
  if self.hasHeader != 0 and (self.bitrateIndex != bitrateIndex or self.samplerateIndex !=
      samplerateIndex or self.mode != mode):
    return 0
  self.bitrateIndex = bitrateIndex
  self.samplerateIndex = samplerateIndex
  self.mode = mode
  self.hasHeader = 1
  # Parse the mode_extension, set up the stereo bound
  if mode == PLM_AUDIO_MODE_JOINT_STEREO:
    self.bound = (plm_buffer_read(self.buffer, 2) + 1) shl 2
  else:
    plm_buffer_skip(self.buffer, 2)
    self.bound = (if mode == PLM_AUDIO_MODE_MONO: 0 else: 32)
  # Discard the last 4 bits of the header and the CRC value, if present
  plm_buffer_skip(self.buffer, 4)
  if hasCRC != 0:
    plm_buffer_skip(self.buffer, 16)
  # Compute frame size, check if we have enough data to decode the whole
  # frame.
  let bitrate: cint = cint(PLM_AUDIO_BIT_RATE[self.bitrateIndex])
  let samplerate: cint = cint(PLM_AUDIO_SAMPLE_RATE[self.samplerateIndex])
  let frameSize: cint = (144000 * bitrate div samplerate) + padding
  return frameSize - (if hasCRC != 0: 6 else: 4)

# The ring position is a multiple of 64 in 0..960. Each window row starts
# on a multiple of 32, so a full row fits both the 512-tap window and V.
{.push checks: off.}
proc synthesizeChannel(self: ptr plm_audio_t, ch, subblock, outPos: int,
    duplicateMono: static bool = false) =
  plm_audio_idct36(self.sample[ch], subblock, self.V[ch], self.vPos)
  let
    windowBase = 512 - (self.vPos shr 1)
    phase = (self.vPos and 127) shr 1
  var accum: array[32, float32]
  # Accumulate each half in stream order to preserve float rounding.
  for half in 0..1:
    let vBase = if half == 0: phase else: 96 - phase
    for tap in 0 ..< 8:
      let
        w = (windowBase + half * 32 + tap * 64) and 511
        v = vBase + tap * 128
      for i in 0 ..< 32:
        accum[i] += PLM_AUDIO_SYNTHESIS_WINDOW[w + i] * self.V[ch][v + i]
  # 36 subblocks of 32 stereo samples fill the 1152-sample MP2 frame.
  for i in 0 ..< 32:
    let sample = accum[i] / -1090519040.0'f32
    self.samples.interleaved[(outPos + i) * 2 + ch] = sample
    when duplicateMono:
      self.samples.interleaved[(outPos + i) * 2 + 1] = sample
{.pop.}

proc plm_audio_decode_frame(self: ptr plm_audio_t) =
  # Prepare the quantizer table lookups
  var tab3: cint = 0
  var sblimit: cint = 0
  let tab1: cint = (if self.mode == PLM_AUDIO_MODE_MONO: 0 else: 1)
  let tab2: cint = cint(PLM_AUDIO_QUANT_LUT_STEP_1[tab1][self.bitrateIndex])
  tab3 = cint(QUANT_LUT_STEP_2[tab2][self.samplerateIndex])
  sblimit = tab3 and 63
  tab3 = tab3 shr 6
  if self.bound > sblimit:
    self.bound = sblimit
  # Read the allocation information
  for sb in 0 ..< self.bound:
    self.allocation[0][sb] = plm_audio_read_allocation(self, sb, tab3)
    self.allocation[1][sb] = plm_audio_read_allocation(self, sb, tab3)
  for sb in self.bound ..< sblimit:
    self.allocation[1][sb] = plm_audio_read_allocation(self, sb, tab3)
    self.allocation[0][sb] = self.allocation[1][sb]
  # Read scale factor selector information
  let channels: cint = (if self.mode == PLM_AUDIO_MODE_MONO: 1 else: 2)
  for sb in 0 ..< sblimit:
    for ch in 0 ..< channels:
      if self.allocation[ch][sb] != nil:
        self.scaleFactorInfo[ch][sb] = uint8(plm_buffer_read(self.buffer, 2))
  # Read scale factors
  for sb in 0 ..< sblimit:
    for ch in 0 ..< channels:
      if self.allocation[ch][sb] != nil:
        let sf = addr(self.scaleFactor[ch][sb][0])
        case cint(self.scaleFactorInfo[ch][sb])
        of 0:
          sf[0] = plm_buffer_read(self.buffer, 6)
          sf[1] = plm_buffer_read(self.buffer, 6)
          sf[2] = plm_buffer_read(self.buffer, 6)
        of 1:
          sf[1] = plm_buffer_read(self.buffer, 6)
          sf[0] = sf[1]
          sf[2] = plm_buffer_read(self.buffer, 6)
        of 2:
          sf[2] = plm_buffer_read(self.buffer, 6)
          sf[1] = sf[2]
          sf[0] = sf[1]
        of 3:
          sf[0] = plm_buffer_read(self.buffer, 6)
          sf[2] = plm_buffer_read(self.buffer, 6)
          sf[1] = sf[2]
        else: discard
  # Bit allocation is fixed for the frame. Clear silent bands once and visit
  # occupied channel/subband pairs in their encoded order for each granule.
  reset self.sample
  var
    active: array[64, tuple[ch, sb: uint8]]
    activeCount = 0
  for sb in 0 ..< sblimit:
    let codedChannels = if sb < self.bound: 2 else: 1
    for ch in 0 ..< codedChannels:
      if self.allocation[ch][sb] != nil:
        active[activeCount] = (uint8(ch), uint8(sb))
        inc activeCount
  # Coefficient input and reconstruction
  var outPos: cint = 0
  for part in 0'i32 ..< 3:
    for granule in 0 ..< 4:
      for i in 0 ..< activeCount:
        let band = active[i]
        plm_audio_read_samples(self, cint(band.ch), cint(band.sb), part)
      if channels == 2 and self.bound < sblimit:
        # Joint-stereo bands carry a single coded sample triplet.
        copyMem(addr self.sample[1][self.bound], addr self.sample[0][self.bound],
          (sblimit - self.bound) * sizeof(self.sample[0][0]))
      # Synthesis loop
      for p in 0 ..< 3:
        # Shifting step
        self.vPos = (self.vPos - 64) and 1023
        if channels == 1:
          synthesizeChannel(self, 0, p, outPos, duplicateMono = true)
        else:
          synthesizeChannel(self, 0, p, outPos)
          synthesizeChannel(self, 1, p, outPos)
        outPos += 32
  plm_buffer_align(self.buffer)

proc plm_audio_read_allocation(self: ptr plm_audio_t, sb: cint,
    tab3: cint): ptr plm_quantizer_spec_t =
  let tab4: cint = cint(PLM_AUDIO_QUANT_LUT_STEP_3[tab3][sb])
  let qtab: cint = cint(PLM_AUDIO_QUANT_LUT_STEP_4[tab4 and 15][plm_buffer_read(self.buffer, tab4 shr 4)])
  return (if qtab != 0: addr(PLM_AUDIO_QUANT_TAB[qtab - 1]) else: nil)

proc plm_audio_read_samples(self: ptr plm_audio_t, ch: cint, sb: cint, part: cint) =
  let q = self.allocation[ch][sb]
  let sample = addr(self.sample[ch][sb][0])
  let sf = scaleFactors[self.scaleFactor[ch][sb][part]]
  # Decode samples
  let levels = cint(q.levels)
  if q.group != 0:
    # Decode grouped samples
    let packed = plm_buffer_read(self.buffer, cint(q.bits))
    sample[0] = packed mod levels
    let upper = packed div levels
    sample[1] = upper mod levels
    sample[2] = upper div levels
  else:
    # Decode direct samples
    sample[0] = plm_buffer_read(self.buffer, cint(q.bits))
    sample[1] = plm_buffer_read(self.buffer, cint(q.bits))
    sample[2] = plm_buffer_read(self.buffer, cint(q.bits))
  # Postmultiply samples
  let midpoint = (levels - 1) shr 1
  for i in 0..<3:
    let centered = (midpoint - sample[i]) * cint(q.scale)
    # A wide product combines the two 12-bit fixed-point shifts exactly.
    sample[i] = cint((int64(centered) * sf + 2048) shr 24)

# Only the synthesis loop calls this transform: ss is 0..2 and the 64
# output slots beginning at dp fit in the 1024-sample ring.
{.push boundChecks: off.}
proc plm_audio_idct36(s: array[32, array[3, cint]], ss: int, d: var array[1024, float32], dp: cint) =
  var t01: float32
  var t02: float32
  var t03: float32
  var t04: float32
  var t05: float32
  var t06: float32
  var t07: float32
  var t08: float32
  var t09: float32
  var t10: float32
  var t11: float32
  var t12: float32
  var t13: float32
  var t14: float32
  var t15: float32
  var t16: float32
  var t17: float32
  var t18: float32
  var t19: float32
  var t20: float32
  var t21: float32
  var t22: float32
  var t23: float32
  var t24: float32
  var t25: float32
  var t26: float32
  var t27: float32
  var t28: float32
  var t29: float32
  var t30: float32
  var t31: float32
  var t32: float32
  var t33: float32
  t01 = float32((s[0][ss] + s[31][ss]))
  t02 = float32((s[0][ss] - s[31][ss])) * 0.500602998235'f32
  t03 = float32((s[1][ss] + s[30][ss]))
  t04 = float32((s[1][ss] - s[30][ss])) * 0.505470959898'f32
  t05 = float32((s[2][ss] + s[29][ss]))
  t06 = float32((s[2][ss] - s[29][ss])) * 0.515447309923'f32
  t07 = float32((s[3][ss] + s[28][ss]))
  t08 = float32((s[3][ss] - s[28][ss])) * 0.53104259109'f32
  t09 = float32((s[4][ss] + s[27][ss]))
  t10 = float32((s[4][ss] - s[27][ss])) * 0.553103896034'f32
  t11 = float32((s[5][ss] + s[26][ss]))
  t12 = float32((s[5][ss] - s[26][ss])) * 0.582934968206'f32
  t13 = float32((s[6][ss] + s[25][ss]))
  t14 = float32((s[6][ss] - s[25][ss])) * 0.622504123036'f32
  t15 = float32((s[7][ss] + s[24][ss]))
  t16 = float32((s[7][ss] - s[24][ss])) * 0.674808341455'f32
  t17 = float32((s[8][ss] + s[23][ss]))
  t18 = float32((s[8][ss] - s[23][ss])) * 0.744536271002'f32
  t19 = float32((s[9][ss] + s[22][ss]))
  t20 = float32((s[9][ss] - s[22][ss])) * 0.839349645416'f32
  t21 = float32((s[10][ss] + s[21][ss]))
  t22 = float32((s[10][ss] - s[21][ss])) * 0.972568237862'f32
  t23 = float32((s[11][ss] + s[20][ss]))
  t24 = float32((s[11][ss] - s[20][ss])) * 1.16943993343'f32
  t25 = float32((s[12][ss] + s[19][ss]))
  t26 = float32((s[12][ss] - s[19][ss])) * 1.48416461631'f32
  t27 = float32((s[13][ss] + s[18][ss]))
  t28 = float32((s[13][ss] - s[18][ss])) * 2.05778100995'f32
  t29 = float32((s[14][ss] + s[17][ss]))
  t30 = float32((s[14][ss] - s[17][ss])) * 3.40760841847'f32
  t31 = float32((s[15][ss] + s[16][ss]))
  t32 = float32((s[15][ss] - s[16][ss])) * 10.1900081235'f32
  t33 = t01 + t31
  t31 = (t01 - t31) * 0.502419286188'f32
  t01 = t03 + t29
  t29 = (t03 - t29) * 0.52249861494'f32
  t03 = t05 + t27
  t27 = (t05 - t27) * 0.566944034816'f32
  t05 = t07 + t25
  t25 = (t07 - t25) * 0.64682178336'f32
  t07 = t09 + t23
  t23 = (t09 - t23) * 0.788154623451'f32
  t09 = t11 + t21
  t21 = (t11 - t21) * 1.06067768599'f32
  t11 = t13 + t19
  t19 = (t13 - t19) * 1.72244709824'f32
  t13 = t15 + t17
  t17 = (t15 - t17) * 5.10114861869'f32
  t15 = t33 + t13
  t13 = (t33 - t13) * 0.509795579104'f32
  t33 = t01 + t11
  t01 = (t01 - t11) * 0.601344886935'f32
  t11 = t03 + t09
  t09 = (t03 - t09) * 0.899976223136'f32
  t03 = t05 + t07
  t07 = (t05 - t07) * 2.56291544774'f32
  t05 = t15 + t03
  t15 = (t15 - t03) * 0.541196100146'f32
  t03 = t33 + t11
  t11 = (t33 - t11) * 1.30656296488'f32
  t33 = t05 + t03
  t05 = (t05 - t03) * 0.707106781187'f32
  t03 = t15 + t11
  t15 = (t15 - t11) * 0.707106781187'f32
  t03 += t15
  t11 = t13 + t07
  t13 = (t13 - t07) * 0.541196100146'f32
  t07 = t01 + t09
  t09 = (t01 - t09) * 1.30656296488'f32
  t01 = t11 + t07
  t07 = (t11 - t07) * 0.707106781187'f32
  t11 = t13 + t09
  t13 = (t13 - t09) * 0.707106781187'f32
  t11 += t13
  t01 += t11
  t11 += t07
  t07 += t13
  t09 = t31 + t17
  t31 = (t31 - t17) * 0.509795579104'f32
  t17 = t29 + t19
  t29 = (t29 - t19) * 0.601344886935'f32
  t19 = t27 + t21
  t21 = (t27 - t21) * 0.899976223136'f32
  t27 = t25 + t23
  t23 = (t25 - t23) * 2.56291544774'f32
  t25 = t09 + t27
  t09 = (t09 - t27) * 0.541196100146'f32
  t27 = t17 + t19
  t19 = (t17 - t19) * 1.30656296488'f32
  t17 = t25 + t27
  t27 = (t25 - t27) * 0.707106781187'f32
  t25 = t09 + t19
  t19 = (t09 - t19) * 0.707106781187'f32
  t25 += t19
  t09 = t31 + t23
  t31 = (t31 - t23) * 0.541196100146'f32
  t23 = t29 + t21
  t21 = (t29 - t21) * 1.30656296488'f32
  t29 = t09 + t23
  t23 = (t09 - t23) * 0.707106781187'f32
  t09 = t31 + t21
  t31 = (t31 - t21) * 0.707106781187'f32
  t09 += t31
  t29 += t09
  t09 += t23
  t23 += t31
  t17 += t29
  t29 += t25
  t25 += t09
  t09 += t27
  t27 += t23
  t23 += t19
  t19 += t31
  t21 = t02 + t32
  t02 = (t02 - t32) * 0.502419286188'f32
  t32 = t04 + t30
  t04 = (t04 - t30) * 0.52249861494'f32
  t30 = t06 + t28
  t28 = (t06 - t28) * 0.566944034816'f32
  t06 = t08 + t26
  t08 = (t08 - t26) * 0.64682178336'f32
  t26 = t10 + t24
  t10 = (t10 - t24) * 0.788154623451'f32
  t24 = t12 + t22
  t22 = (t12 - t22) * 1.06067768599'f32
  t12 = t14 + t20
  t20 = (t14 - t20) * 1.72244709824'f32
  t14 = t16 + t18
  t16 = (t16 - t18) * 5.10114861869'f32
  t18 = t21 + t14
  t14 = (t21 - t14) * 0.509795579104'f32
  t21 = t32 + t12
  t32 = (t32 - t12) * 0.601344886935'f32
  t12 = t30 + t24
  t24 = (t30 - t24) * 0.899976223136'f32
  t30 = t06 + t26
  t26 = (t06 - t26) * 2.56291544774'f32
  t06 = t18 + t30
  t18 = (t18 - t30) * 0.541196100146'f32
  t30 = t21 + t12
  t12 = (t21 - t12) * 1.30656296488'f32
  t21 = t06 + t30
  t30 = (t06 - t30) * 0.707106781187'f32
  t06 = t18 + t12
  t12 = (t18 - t12) * 0.707106781187'f32
  t06 += t12
  t18 = t14 + t26
  t26 = (t14 - t26) * 0.541196100146'f32
  t14 = t32 + t24
  t24 = (t32 - t24) * 1.30656296488'f32
  t32 = t18 + t14
  t14 = (t18 - t14) * 0.707106781187'f32
  t18 = t26 + t24
  t24 = (t26 - t24) * 0.707106781187'f32
  t18 += t24
  t32 += t18
  t18 += t14
  t26 = t14 + t24
  t14 = t02 + t16
  t02 = (t02 - t16) * 0.509795579104'f32
  t16 = t04 + t20
  t04 = (t04 - t20) * 0.601344886935'f32
  t20 = t28 + t22
  t22 = (t28 - t22) * 0.899976223136'f32
  t28 = t08 + t10
  t10 = (t08 - t10) * 2.56291544774'f32
  t08 = t14 + t28
  t14 = (t14 - t28) * 0.541196100146'f32
  t28 = t16 + t20
  t20 = (t16 - t20) * 1.30656296488'f32
  t16 = t08 + t28
  t28 = (t08 - t28) * 0.707106781187'f32
  t08 = t14 + t20
  t20 = (t14 - t20) * 0.707106781187'f32
  t08 += t20
  t14 = t02 + t10
  t02 = (t02 - t10) * 0.541196100146'f32
  t10 = t04 + t22
  t22 = (t04 - t22) * 1.30656296488'f32
  t04 = t14 + t10
  t10 = (t14 - t10) * 0.707106781187'f32
  t14 = t02 + t22
  t02 = (t02 - t22) * 0.707106781187'f32
  t14 += t02
  t04 += t14
  t14 += t10
  t10 += t02
  t16 += t04
  t04 += t08
  t08 += t14
  t14 += t28
  t28 += t10
  t10 += t20
  t20 += t02
  t21 += t16
  t16 += t32
  t32 += t04
  t04 += t06
  t06 += t08
  t08 += t18
  t18 += t14
  t14 += t30
  t30 += t28
  t28 += t26
  t26 += t10
  t10 += t12
  t12 += t20
  t20 += t24
  t24 += t02
  d[dp + 48] = -t33
  d[dp + 47] = -t21
  d[dp + 49] = d[dp + 47]
  d[dp + 46] = -t17
  d[dp + 50] = d[dp + 46]
  d[dp + 45] = -t16
  d[dp + 51] = d[dp + 45]
  d[dp + 44] = -t01
  d[dp + 52] = d[dp + 44]
  d[dp + 43] = -t32
  d[dp + 53] = d[dp + 43]
  d[dp + 42] = -t29
  d[dp + 54] = d[dp + 42]
  d[dp + 41] = -t04
  d[dp + 55] = d[dp + 41]
  d[dp + 40] = -t03
  d[dp + 56] = d[dp + 40]
  d[dp + 39] = -t06
  d[dp + 57] = d[dp + 39]
  d[dp + 38] = -t25
  d[dp + 58] = d[dp + 38]
  d[dp + 37] = -t08
  d[dp + 59] = d[dp + 37]
  d[dp + 36] = -t11
  d[dp + 60] = d[dp + 36]
  d[dp + 35] = -t18
  d[dp + 61] = d[dp + 35]
  d[dp + 34] = -t09
  d[dp + 62] = d[dp + 34]
  d[dp + 33] = -t14
  d[dp + 63] = d[dp + 33]
  d[dp + 32] = -t05
  d[dp + 0] = t05
  d[dp + 31] = -t30
  d[dp + 1] = t30
  d[dp + 30] = -t27
  d[dp + 2] = t27
  d[dp + 29] = -t28
  d[dp + 3] = t28
  d[dp + 28] = -t07
  d[dp + 4] = t07
  d[dp + 27] = -t26
  d[dp + 5] = t26
  d[dp + 26] = -t23
  d[dp + 6] = t23
  d[dp + 25] = -t10
  d[dp + 7] = t10
  d[dp + 24] = -t15
  d[dp + 8] = t15
  d[dp + 23] = -t12
  d[dp + 9] = t12
  d[dp + 22] = -t19
  d[dp + 10] = t19
  d[dp + 21] = -t20
  d[dp + 11] = t20
  d[dp + 20] = -t13
  d[dp + 12] = t13
  d[dp + 19] = -t24
  d[dp + 13] = t24
  d[dp + 18] = -t31
  d[dp + 14] = t31
  d[dp + 17] = -t02
  d[dp + 15] = t02
  d[dp + 16] = 0.0'f32
{.pop.}
