import bindings

type
  MpegError* = object of CatchableError

  DecoderObj = object
    handle: ptr plm_t
    file: File
    data: string

  Decoder* = ref DecoderObj

  VideoFrame* = object
    time*: float64
    width*, height*: int
    rgba*: seq[uint8]

  AudioFrame* = object
    time*: float64
    sampleRate*: int
    samples*: seq[float32]
      ## Interleaved left and right samples, including duplicated mono audio.

proc release(decoder: var DecoderObj) {.raises: [].} =
  ## Releases the native decoder before its file and retained memory.
  if decoder.handle != nil:
    plm_destroy(decoder.handle)
    decoder.handle = nil
  if decoder.file != nil:
    close(decoder.file)
    decoder.file = nil
  decoder.data = ""

proc `=destroy`(decoder: var DecoderObj) {.raises: [].} =
  ## Releases resources when the last reference to a decoder is dropped.
  decoder.release()

proc close*(decoder: Decoder) {.raises: [].} =
  ## Releases a decoder immediately; repeated calls are harmless.
  if decoder != nil:
    decoder[].release()

proc raw*(decoder: Decoder): ptr plm_t {.raises: [MpegError].} =
  ## Borrows the decoder handle until close; the caller must not destroy it.
  if decoder == nil or decoder.handle == nil:
    raise newException(MpegError, "The MPEG decoder is closed.")
  return decoder.handle

proc validate(decoder: Decoder) {.raises: [MpegError].} =
  ## Rejects files without usable MPEG Program Stream and codec headers.
  if decoder.handle == nil or plm_has_headers(decoder.handle) == 0:
    decoder.close()
    raise newException(MpegError, "Missing or invalid MPEG stream headers.")
  if plm_get_num_video_streams(decoder.handle) == 0 and
    plm_get_num_audio_streams(decoder.handle) == 0:
      decoder.close()
      raise newException(MpegError, "The MPEG file has no supported streams.")

proc openMpeg*(path: string): Decoder {.raises: [MpegError].} =
  ## Opens a file for incremental decoding, including Unicode file paths.
  if path.len == 0 or '\0' in path:
    raise newException(MpegError, "The MPEG file path is empty or invalid.")
  result = Decoder()
  try:
    result.file = open(path, fmRead)
  except IOError as error:
    raise newException(MpegError, "Cannot open MPEG file: " & error.msg)
  result.handle = plm_create_with_file(result.file, 0)
  result.validate()

proc newMpeg*(data: string): Decoder {.raises: [MpegError].} =
  ## Retains an owned string of MPEG data for in-memory decoding.
  if data.len == 0:
    raise newException(MpegError, "The MPEG data is empty.")
  result = Decoder(data: data)
  result.handle = plm_create_with_memory(
    cast[ptr uint8](addr result.data[0]), csize_t(result.data.len), 0
  )
  result.validate()

proc width*(decoder: Decoder): int {.raises: [MpegError].} =
  ## Returns the display width in pixels.
  int(plm_get_width(decoder.raw))

proc height*(decoder: Decoder): int {.raises: [MpegError].} =
  ## Returns the display height in pixels.
  int(plm_get_height(decoder.raw))

proc frameRate*(decoder: Decoder): float64 {.raises: [MpegError].} =
  ## Returns the video frame rate in frames per second.
  plm_get_framerate(decoder.raw)

proc sampleRate*(decoder: Decoder): int {.raises: [MpegError].} =
  ## Returns the audio sample rate, or zero when there is no audio.
  int(plm_get_samplerate(decoder.raw))

proc hasAudio*(decoder: Decoder): bool {.raises: [MpegError].} =
  ## Returns whether the file contains an audio stream.
  plm_get_num_audio_streams(decoder.raw) > 0

proc duration*(decoder: Decoder): float64 {.raises: [MpegError].} =
  ## Estimates video duration from packet timestamps; scans the file tail.
  plm_get_duration(decoder.raw)

proc `audioEnabled=`*(decoder: Decoder, enabled: bool)
    {.raises: [MpegError].} =
  ## Enables audio decoding; disable unused streams to avoid buffering them.
  plm_set_audio_enabled(decoder.raw, cint(enabled))

proc `videoEnabled=`*(decoder: Decoder, enabled: bool)
    {.raises: [MpegError].} =
  ## Enables video decoding; disable unused streams to avoid buffering them.
  plm_set_video_enabled(decoder.raw, cint(enabled))

proc rewind*(decoder: Decoder) {.raises: [MpegError].} =
  ## Rewinds both streams and clears their end-of-file state.
  plm_rewind(decoder.raw)

proc decodeVideo*(decoder: Decoder, frame: var VideoFrame): bool
    {.raises: [MpegError].} =
  ## Decodes into a reusable owned RGBA buffer; false leaves it unchanged.
  ## False means end of stream, a disabled stream, or undecodable data.
  let decoded = plm_decode_video(decoder.raw)
  if decoded == nil:
    return false
  frame.time = decoded.time
  frame.width = int(decoded.width)
  frame.height = int(decoded.height)
  frame.rgba.setLen(frame.width * frame.height * 4)
  frameToOpaqueRgba(decoded, addr frame.rgba[0], cint(frame.width * 4))
  return true

proc decodeAudio*(decoder: Decoder, frame: var AudioFrame): bool
    {.raises: [MpegError].} =
  ## Decodes into reusable interleaved stereo floats; false leaves it unchanged.
  ## False means end of stream, a disabled stream, or undecodable data.
  let decoded = plm_decode_audio(decoder.raw)
  if decoded == nil:
    return false
  frame.time = decoded.time
  frame.sampleRate = decoder.sampleRate
  frame.samples.setLen(int(decoded.count) * 2)
  copyMem(
    addr frame.samples[0],
    addr decoded.interleaved[0],
    frame.samples.len * sizeof(float32)
  )
  return true

proc pcm16*(frame: AudioFrame, dest: var openArray[int16]): int {.raises: [].} =
  ## Writes clipped PCM samples and returns the number that fit in dest.
  ## Non-finite values clip to the endpoints for infinities and to silence for NaN.
  result = min(frame.samples.len, dest.len)
  # The loop fits both buffers. Finite scaled samples fit in int16 after
  # rounding. Add the half-unit in float64 to preserve float32 near-ties.
  {.push checks: off.}
  for i in 0 ..< result:
    let sample = frame.samples[i]
    if sample >= 1.0'f:
      dest[i] = 32767
    elif sample <= -1.0'f:
      dest[i] = -32767
    elif sample != sample:
      dest[i] = 0
    else:
      let scaled = float64(sample * 32767.0'f)
      dest[i] = int16(scaled + (if scaled < 0: -0.5 else: 0.5))
  {.pop.}

proc pcm16*(frame: AudioFrame): seq[int16] {.raises: [].} =
  ## Returns an owned copy of the frame as signed 16-bit stereo PCM.
  result = newSeqUninit[int16](frame.samples.len)
  discard frame.pcm16(result)
