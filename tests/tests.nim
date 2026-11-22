import std/[math, os, unittest]

when defined(mpegReference):
  import reference/mpeg
else:
  import mpeg

const DataPath = currentSourcePath().parentDir / "data"

type
  Playback = object
    videos, audios, samples: int
    videoTime, audioTime: float64
    energy: float64

  Input = object
    data: string
    position: int
    loads, seeks: int

proc onVideo(decoder: ptr plm_t, frame: ptr plm_frame_t, user: pointer)
    {.cdecl, raises: [].} =
  ## Counts video frames delivered through the C callback boundary.
  let playback = cast[ptr Playback](user)
  inc playback.videos
  playback.videoTime = frame.time

proc onAudio(decoder: ptr plm_t, frame: ptr plm_samples_t, user: pointer)
    {.cdecl, raises: [].} =
  ## Counts stereo sample frames and measures callback audio energy.
  let playback = cast[ptr Playback](user)
  inc playback.audios
  playback.samples += int(frame.count)
  playback.audioTime = frame.time
  for i in 0 ..< int(frame.count) * 2:
    playback.energy += float64(frame.interleaved[i]) ^ 2

proc loadInput(buffer: ptr plm_buffer_t, user: pointer)
    {.cdecl, raises: [].} =
  ## Supplies small chunks to exercise packet boundaries and refilling.
  let
    input = cast[ptr Input](user)
    count = min(733, input.data.len - input.position)
  inc input.loads
  if count > 0:
    discard plm_buffer_write(
      buffer,
      cast[ptr uint8](addr input.data[input.position]),
      csize_t(count)
    )
    input.position += count
  if input.position == input.data.len:
    plm_buffer_signal_end(buffer)

proc seekInput(buffer: ptr plm_buffer_t, offset: csize_t, user: pointer)
    {.cdecl, raises: [].} =
  ## Repositions the custom input when the decoder rewinds or seeks.
  let input = cast[ptr Input](user)
  input.position = min(int(offset), input.data.len)
  inc input.seeks

proc tellInput(buffer: ptr plm_buffer_t, user: pointer): csize_t
    {.cdecl, raises: [].} =
  ## Returns the custom input's byte position.
  csize_t(cast[ptr Input](user).position)

proc referenceSample(data: string, index: int): float32 =
  ## Reads a little-endian reference float without alignment assumptions.
  var bits: uint32
  for i in 0 ..< 4:
    bits = bits or (uint32(uint8(data[index * 4 + i])) shl (i * 8))
  return cast[float32](bits)

suite "MPEG decoding":
  test "file metadata and video frames include padded edges and B frames":
    let decoder = openMpeg(DataPath / "stereo.mpg")
    defer: decoder.close()
    decoder.audioEnabled = false
    check decoder.width == 162
    check decoder.height == 98
    check decoder.frameRate == 30
    check decoder.sampleRate == 48000
    check decoder.hasAudio
    var
      frame: VideoFrame
      count = 0
      first: seq[uint8]
    while decoder.decodeVideo(frame):
      check frame.rgba.len == 162 * 98 * 4
      check abs(frame.time - float64(count) / 30) < 0.000001
      if count == 0:
        first = frame.rgba
      for i in countup(3, frame.rgba.high, 4):
        check frame.rgba[i] == 255
      inc count
    check count == 60
    check frame.rgba != first
    check not decoder.decodeVideo(frame)

  test "first and final RGB frames agree with an independent decoder":
    let decoder = openMpeg(DataPath / "stereo.mpg")
    defer: decoder.close()
    decoder.audioEnabled = false
    var frame: VideoFrame
    for index in 0 ..< 60:
      require decoder.decodeVideo(frame)
      if index in [0, 59]:
        let
          name =
            if index == 0:
              "stereo.rgb"
            else:
              "stereo-last.rgb"
          reference = readFile(DataPath / name)
        require reference.len == frame.width * frame.height * 3
        var difference: float64
        for pixel in 0 ..< frame.width * frame.height:
          for channel in 0 ..< 3:
            difference += abs(float64(
              int(frame.rgba[pixel * 4 + channel]) -
              int(uint8(reference[pixel * 3 + channel]))
            ))
        # The decoders use different chroma interpolation and rounding.
        check difference / float64(reference.len) < 6.0

  test "stereo PCM agrees with FFmpeg in channels, phase, and volume":
    let
      decoder = openMpeg(DataPath / "stereo.mpg")
      reference = readFile(DataPath / "stereo.f32")
    defer: decoder.close()
    decoder.videoEnabled = false
    var
      frame: AudioFrame
      offset = 0
      difference, expected, correlation: float64
      energy: array[2, float64]
    for packet in 0 ..< 6:
      require decoder.decodeAudio(frame)
      check frame.sampleRate == 48000
      check frame.samples.len == 1152 * 2
      check abs(frame.time - float64(packet * 1152) / 48000) < 0.000001
      for i, sample in frame.samples:
        let reference = referenceSample(reference, offset + i)
        difference += float64(sample - reference) ^ 2
        expected += float64(reference) ^ 2
        correlation += float64(sample * reference)
        energy[i mod 2] += float64(sample) ^ 2
      offset += frame.samples.len
    check offset * 4 == reference.len
    check sqrt(difference / float64(offset)) < 0.007
    check correlation / expected > 0.90
    check correlation / expected < 1.10
    check energy[0] / energy[1] > 3.5
    check energy[0] / energy[1] < 4.5

  test "audio reaches its final packet and rewinds after EOF":
    let decoder = openMpeg(DataPath / "stereo.mpg")
    defer: decoder.close()
    decoder.videoEnabled = false
    var
      frame: AudioFrame
      count = 0
    while decoder.decodeAudio(frame):
      count += frame.samples.len div 2
    check count == 84 * 1152
    check plm_has_ended(decoder.raw) != 0
    decoder.rewind()
    check plm_has_ended(decoder.raw) == 0
    require decoder.decodeAudio(frame)
    check frame.time == 0

  test "mono at 44100 Hz is returned in both stereo channels":
    let decoder = openMpeg(DataPath / "mono.mpg")
    defer: decoder.close()
    decoder.videoEnabled = false
    check decoder.sampleRate == 44100
    var
      frame: AudioFrame
      count = 0
      energy: float64
    while decoder.decodeAudio(frame):
      for i in countup(0, frame.samples.high, 2):
        check frame.samples[i] == frame.samples[i + 1]
        energy += float64(frame.samples[i]) ^ 2
      inc count
    check count == 39
    check energy > 10

  test "video-only streams need no audio decoder":
    let decoder = openMpeg(DataPath / "video.mpg")
    defer: decoder.close()
    check not decoder.hasAudio
    check decoder.sampleRate == 0
    check decoder.frameRate == 25
    var
      video: VideoFrame
      audio: AudioFrame
      count = 0
    check not decoder.decodeAudio(audio)
    while decoder.decodeVideo(video):
      inc count
    check count == 12
    decoder.rewind()
    require decoder.decodeVideo(video)
    check video.time == 0

  test "memory decoding retains data after the caller changes its string":
    var data = readFile(DataPath / "video.mpg")
    let decoder = newMpeg(data)
    defer: decoder.close()
    data[0] = 'X'
    data.setLen(0)
    var frame: VideoFrame
    require decoder.decodeVideo(frame)
    check frame.width == 64
    check frame.height == 48

  test "invalid inputs and closed decoders report MpegError":
    expect MpegError:
      discard openMpeg(DataPath / "missing.mpg")
    expect MpegError:
      discard openMpeg("bad\0path")
    for data in ["", "not a movie", "\0\0\1\xBA"]:
      expect MpegError:
        discard newMpeg(data)
    let decoder = openMpeg(DataPath / "video.mpg")
    decoder.close()
    decoder.close()
    var frame: VideoFrame
    expect MpegError:
      discard decoder.decodeVideo(frame)

  test "owned frames survive decoder cleanup":
    var
      video: VideoFrame
      audio: AudioFrame
    block:
      let decoder = newMpeg(readFile(DataPath / "stereo.mpg"))
      require decoder.decodeVideo(video)
      require decoder.decodeAudio(audio)
    check video.rgba.len == 162 * 98 * 4
    check video.rgba[3] == 255
    check audio.samples.len == 1152 * 2
    check audio.pcm16.len == audio.samples.len

  test "automatic cleanup closes the native file handle":
    let path = getTempDir() / ("mpeg-owned-" & $getCurrentProcessId() & ".mpg")
    copyFile(DataPath / "video.mpg", path)
    block:
      let decoder = openMpeg(path)
      var frame: VideoFrame
      require decoder.decodeVideo(frame)
    removeFile(path)
    check not fileExists(path)

  test "Unicode filenames use Nim's file opening":
    let path = getTempDir() / ("mpeg-映画-" & $getCurrentProcessId() & ".mpg")
    copyFile(DataPath / "video.mpg", path)
    defer: removeFile(path)
    let decoder = openMpeg(path)
    defer: decoder.close()
    var frame: VideoFrame
    check decoder.decodeVideo(frame)

  test "float audio converts to clipped signed PCM":
    let frame = AudioFrame(samples: @[-2.0'f, -1, 0, 0.5, 1, 2])
    check frame.pcm16 == @[-32767'i16, -32767, 0, 16384, 32767, 32767]

suite "PL_MPEG native API":
  test "timed callbacks deliver all video and audio through the C ABI":
    let decoder = openMpeg(DataPath / "stereo.mpg")
    defer: decoder.close()
    var playback: Playback
    plm_set_video_decode_callback(decoder.raw, onVideo, addr playback)
    plm_set_audio_decode_callback(decoder.raw, onAudio, addr playback)
    plm_set_audio_lead_time(decoder.raw, 0.05)
    for i in 0 ..< 250:
      plm_decode(decoder.raw, 0.01)
    check playback.videos == 60
    check playback.audios == 84
    check playback.samples == 84 * 1152
    check playback.energy > 100
    check abs(playback.videoTime - playback.audioTime) < 0.05
    check plm_has_ended(decoder.raw) != 0

  test "seeking delivers the target frame and resynchronizes audio":
    let decoder = openMpeg(DataPath / "stereo.mpg")
    defer: decoder.close()
    var playback: Playback
    plm_set_video_decode_callback(decoder.raw, onVideo, addr playback)
    plm_set_audio_decode_callback(decoder.raw, onAudio, addr playback)
    plm_set_audio_lead_time(decoder.raw, 0.05)
    check decoder.duration > 1.8
    check decoder.duration <= 2.1
    require plm_seek(decoder.raw, 1.0, 1) != 0
    check playback.videos == 1
    check playback.videoTime >= 1.0
    check playback.videoTime < 1.04
    check playback.audios > 0
    check abs(playback.videoTime - playback.audioTime) < 0.10
    plm_decode(decoder.raw, 0.1)
    check playback.videos > 1

  test "looping produces video and audio across the end boundary":
    let decoder = openMpeg(DataPath / "stereo.mpg")
    defer: decoder.close()
    var playback: Playback
    plm_set_video_decode_callback(decoder.raw, onVideo, addr playback)
    plm_set_audio_decode_callback(decoder.raw, onAudio, addr playback)
    plm_set_loop(decoder.raw, 1)
    for i in 0 ..< 450:
      plm_decode(decoder.raw, 0.01)
    check playback.videos >= 120
    check playback.audios >= 168
    check plm_has_ended(decoder.raw) == 0

  test "RGB stride preserves padding and channel order":
    let decoder = openMpeg(DataPath / "stereo.mpg")
    defer: decoder.close()
    decoder.audioEnabled = false
    let frame = plm_decode_video(decoder.raw)
    require frame != nil
    let stride = int(frame.width) * 3 + 19
    var
      rgb = newSeq[uint8](stride * int(frame.height))
      bgr = rgb
    for i in 0 ..< rgb.len:
      rgb[i] = 77
      bgr[i] = 77
    plm_frame_to_rgb(frame, addr rgb[0], cint(stride))
    plm_frame_to_bgr(frame, addr bgr[0], cint(stride))
    for y in 0 ..< int(frame.height):
      for x in 0 ..< int(frame.width):
        let i = y * stride + x * 3
        check rgb[i] == bgr[i + 2]
        check rgb[i + 1] == bgr[i + 1]
        check rgb[i + 2] == bgr[i]
      for x in int(frame.width) * 3 ..< stride:
        check rgb[y * stride + x] == 77

  test "custom input callbacks support chunk boundaries and rewind":
    var input = Input(data: readFile(DataPath / "stereo.mpg"))
    let
      buffer = plm_buffer_create_with_callbacks(
        loadInput, seekInput, tellInput, csize_t(input.data.len), addr input
      )
      decoder = plm_create_with_buffer(buffer, 1)
    require decoder != nil
    defer: plm_destroy(decoder)
    plm_set_audio_enabled(decoder, 0)
    var count = 0
    for i in 0 ..< 2000:
      if plm_decode_video(decoder) != nil:
        inc count
      if plm_has_ended(decoder) != 0:
        break
    check count == 60
    check input.loads > 100
    plm_rewind(decoder)
    check input.seeks > 0
    var frame: ptr plm_frame_t
    for i in 0 ..< 100:
      frame = plm_decode_video(decoder)
      if frame != nil:
        break
    require frame != nil
    check frame.time == 0

  test "original audio selection and packed RGB calls still work":
    let decoder = openMpeg(DataPath / "stereo.mpg")
    defer: decoder.close()
    plm_set_audio_enabled(decoder.raw, 0, 0)
    let frame = plm_decode_video(decoder.raw)
    require frame != nil
    var rgb = newSeq[uint8](int(frame.width * frame.height) * 3)
    plm_frame_to_rgb(frame, addr rgb[0])
    check PLM_DEMUX_PACKET_AUDIO_4 == 0xC3
    check PLM_AUDIO_SAMPLES_PER_FRAME == 1152

when not defined(mpegReference):
  suite "Native Nim regressions":
    test "PCM conversion reuses the supplied storage and reports samples written":
      let frame = AudioFrame(samples: @[-2.0'f32, -0.5, 0, 0.5, 2])
      var dest = [0'i16, 0, 0, 0, 0, 123]
      check frame.pcm16(dest) == 5
      check dest == [-32767'i16, -16384, 0, 16384, 32767, 123]
      check frame.pcm16(dest.toOpenArray(1, 2)) == 2
      check dest[1..2] == [-32767'i16, -16384]
      check AudioFrame().pcm16(dest) == 0

    test "PCM rounding agrees with round for floats adjacent to half steps":
      var frame = AudioFrame(samples: newSeq[float32](3))
      var dest: array[3, int16]
      for level in [-32767, -16384, -128, -1, 0, 127, 16383, 32766]:
        let bits = cast[uint32]((float32(level) + 0.5'f32) / 32767.0'f32)
        for i in 0..<3:
          frame.samples[i] = cast[float32](bits - 1 + uint32(i))
        check frame.pcm16(dest) == 3
        for i, sample in frame.samples:
          check dest[i] == int16(round(sample * 32767.0'f32))
      frame.samples = @[float32(NegInf), float32(NaN), float32(Inf)]
      discard frame.pcm16(dest)
      check dest == [-32767'i16, 0, 32767]

    test "batched PCM conversion clips each lane and preserves the tail":
      let frame = AudioFrame(samples: @[1.5'f32, -0.5, 0, 0.5, -2, 0.25, -0.25,
        float32(NaN), -1, 1, float32(Inf), float32(NegInf), -0.75, 0.75, 0.125,
        -0.125, 0.625])
      for count in 1..frame.samples.len:
        var dest: array[19, int16]
        for sample in dest.mitems: sample = 123
        check frame.pcm16(dest.toOpenArray(1, count)) == count
        for i in 0..<count:
          let x = frame.samples[i]
          let expected = if x != x: 0'i16
                         else: int16(round(clamp(x, -1'f32, 1'f32) * 32767'f32))
          check dest[i + 1] == expected
        check dest[0] == 123
        check dest[count + 1] == 123

    when defined(nimAllocStats):
      test "warmed RGBA and PCM decoding reuses all frame storage":
        let
          video = openMpeg(DataPath / "stereo.mpg")
          audio = openMpeg(DataPath / "stereo.mpg")
        defer:
          video.close()
          audio.close()
        video.audioEnabled = false
        audio.videoEnabled = false
        var
          v: VideoFrame
          a: AudioFrame
          pcm: array[PlmAudioSamplesPerFrame * 2, int16]
          frames, samples: int
        require video.decodeVideo(v) and audio.decodeAudio(a)
        video.rewind()
        audio.rewind()
        let initial = getAllocStats()
        while video.decodeVideo(v):
          inc frames
        while audio.decodeAudio(a):
          samples += a.pcm16(pcm)
        let delta = getAllocStats() - initial
        check frames == 60
        check samples == 84 * pcm.len
        check delta == default(typeof(delta))

    test "all six pixel layouts respect odd dimensions, alpha, and stride":
      type ConvertPixels = proc(frame: ptr plm_frame_t, dest: ptr uint8,
          stride: cint) {.cdecl, raises: [].}
      var
        y = [100'u8, 100, 100, 0, 100, 100, 100, 0, 100, 100, 100, 0]
        cb = [90'u8, 90, 0, 90, 128, 0]
        cr = [170'u8, 170, 0, 0, 170, 128, 0, 0]
        frame = plm_frame_t(
          width: 3, height: 3,
          y: plm_plane_t(width: 4, height: 3, data: addr y[0]),
          cb: plm_plane_t(width: 3, height: 2, data: addr cb[0]),
          cr: plm_plane_t(width: 4, height: 2, data: addr cr[0])
        )
      let formats: array[6, (string, ConvertPixels)] = [
        ("rgb", ConvertPixels(plm_frame_to_rgb)), ("bgr", plm_frame_to_bgr),
        ("rgba", plm_frame_to_rgba), ("bgra", plm_frame_to_bgra),
        ("argb", plm_frame_to_argb), ("abgr", plm_frame_to_abgr)
      ]
      for (order, convert) in formats:
        let stride = 3 * order.len + 2
        var output = newSeq[uint8](3 * stride)
        for value in output.mitems:
          value = 55
        convert(addr frame, addr output[0], cint(stride))
        for row in 0 ..< 3:
          for col in 0 ..< 3:
            for offset, channel in order:
              let expected =
                if channel == 'a': 55
                elif row == 2 and col == 2: 97
                elif channel == 'r': 164
                elif channel == 'g': 78
                else: 20
              check int(output[row * stride + col * order.len + offset]) == expected
          check output[row * stride + stride - 2] == 55
          check output[row * stride + stride - 1] == 55

    test "ring and append buffers grow from zero and preserve rewind semantics":
      let data = readFile(DataPath / "video.mpg")
      for append in [false, true]:
        let buffer =
          if append: plm_buffer_create_for_appending(0)
          else: plm_buffer_create_with_capacity(0)
        defer: plm_buffer_destroy(buffer)
        for offset in countup(0, data.high, 37):
          let size = csize_t(min(37, data.len - offset))
          check plm_buffer_write(buffer, cast[ptr uint8](addr data[offset]), size) == size
        check plm_buffer_get_size(buffer) == csize_t(data.len)
        check plm_buffer_get_remaining(buffer) == csize_t(data.len)
        plm_buffer_signal_end(buffer)
        let decoder = plm_create_with_buffer(buffer, 0)
        defer: plm_destroy(decoder)
        var count = 0
        while plm_decode_video(decoder) != nil:
          inc count
        check count == 12
        plm_rewind(decoder)
        if append:
          check plm_decode_video(decoder) != nil
        else:
          check plm_buffer_get_size(buffer) == 0
          check plm_decode_video(decoder) == nil
