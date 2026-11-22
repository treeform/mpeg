proc plm_init_decoders(self: ptr plm_t): cint
proc plm_handle_end(self: ptr plm_t)
proc plm_read_video_packet(buffer: ptr plm_buffer_t, user: pointer)
proc plm_read_audio_packet(buffer: ptr plm_buffer_t, user: pointer)
proc plm_read_packets(self: ptr plm_t, requestedType: cint)

proc plm_create_with_filename*(filename: cstring): ptr plm_t =
  let buffer = plm_buffer_create_with_filename(filename)
  if buffer == nil:
    return nil
  return plm_create_with_buffer(buffer, 1)

proc plm_create_with_file*(fh: File, closeWhenDone: cint): ptr plm_t =
  let buffer = plm_buffer_create_with_file(fh, closeWhenDone)
  return plm_create_with_buffer(buffer, 1)

proc plm_create_with_memory*(bytes: ptr uint8, length: csize_t, freeWhenDone: cint): ptr plm_t =
  let buffer = plm_buffer_create_with_memory(bytes, length, freeWhenDone)
  return plm_create_with_buffer(buffer, 1)

proc plm_create_with_buffer*(buffer: ptr plm_buffer_t, destroyWhenDone: cint): ptr plm_t =
  if buffer == nil:
    return nil
  let self = createShared(plm_t)
  self.demux = plm_demux_create(buffer, destroyWhenDone)
  self.videoEnabled = 1
  self.audioEnabled = 1
  discard plm_init_decoders(self)
  return self

proc plm_init_decoders(self: ptr plm_t): cint =
  if self.hasDecoders != 0:
    return 1
  if plm_demux_has_headers(self.demux) == 0:
    return 0
  if plm_demux_get_num_video_streams(self.demux) > 0:
    if self.videoEnabled != 0:
      self.videoPacketType = PLM_DEMUX_PACKET_VIDEO_1
    if self.videoDecoder == nil:
      self.videoBuffer = plm_buffer_create_with_capacity(DefaultBufferSize)
      plm_buffer_set_load_callback(self.videoBuffer, plm_read_video_packet, self)
      self.videoDecoder = plm_video_create_with_buffer(self.videoBuffer, 1)
  if plm_demux_get_num_audio_streams(self.demux) > 0:
    if self.audioEnabled != 0:
      self.audioPacketType = PLM_DEMUX_PACKET_AUDIO_1 + self.audioStreamIndex
    if self.audioDecoder == nil:
      self.audioBuffer = plm_buffer_create_with_capacity(DefaultBufferSize)
      plm_buffer_set_load_callback(self.audioBuffer, plm_read_audio_packet, self)
      self.audioDecoder = plm_audio_create_with_buffer(self.audioBuffer, 1)
  self.hasDecoders = 1
  return 1

proc plm_destroy*(self: ptr plm_t) =
  if self.videoDecoder != nil:
    plm_video_destroy(self.videoDecoder)
  if self.audioDecoder != nil:
    plm_audio_destroy(self.audioDecoder)
  plm_demux_destroy(self.demux)
  deallocShared(self)

proc plm_get_audio_enabled*(self: ptr plm_t): cint =
  return self.audioEnabled

proc plm_has_headers*(self: ptr plm_t): cint =
  if plm_demux_has_headers(self.demux) == 0:
    return 0
  if plm_init_decoders(self) == 0:
    return 0
  if self.videoDecoder != nil and plm_video_has_header(self.videoDecoder) == 0 or
      self.audioDecoder != nil and plm_audio_has_header(self.audioDecoder) == 0:
    return 0
  return 1

proc plm_probe*(self: ptr plm_t, probesize: csize_t): cint =
  let foundStreams: cint = plm_demux_probe(self.demux, probesize)
  if foundStreams == 0:
    return 0
  # Re-init decoders
  self.hasDecoders = 0
  self.videoPacketType = 0
  self.audioPacketType = 0
  return plm_init_decoders(self)

proc plm_set_audio_enabled*(self: ptr plm_t, enabled: cint) =
  self.audioEnabled = enabled
  if enabled == 0:
    self.audioPacketType = 0
    return
  self.audioPacketType = (if plm_init_decoders(self) != 0 and self.audioDecoder !=
      nil: PLM_DEMUX_PACKET_AUDIO_1 + self.audioStreamIndex else: 0)

proc plm_set_audio_stream*(self: ptr plm_t, streamIndex: cint) =
  if streamIndex < 0 or streamIndex > 3:
    return
  self.audioStreamIndex = streamIndex
  # Set the correct audio_packet_type
  plm_set_audio_enabled(self, self.audioEnabled)

proc plm_get_video_enabled*(self: ptr plm_t): cint =
  return self.videoEnabled

proc plm_set_video_enabled*(self: ptr plm_t, enabled: cint) =
  self.videoEnabled = enabled
  if enabled == 0:
    self.videoPacketType = 0
    return
  self.videoPacketType = (if plm_init_decoders(self) != 0 and self.videoDecoder !=
      nil: PLM_DEMUX_PACKET_VIDEO_1 else: 0)

proc plm_get_num_video_streams*(self: ptr plm_t): cint =
  return plm_demux_get_num_video_streams(self.demux)

proc plm_get_width*(self: ptr plm_t): cint =
  return (if plm_init_decoders(self) != 0 and self.videoDecoder != nil: plm_video_get_width(
      self.videoDecoder) else: 0)

proc plm_get_height*(self: ptr plm_t): cint =
  return (if plm_init_decoders(self) != 0 and self.videoDecoder != nil: plm_video_get_height(
      self.videoDecoder) else: 0)

proc plm_get_framerate*(self: ptr plm_t): float64 =
  return (if plm_init_decoders(self) != 0 and self.videoDecoder != nil: plm_video_get_framerate(
      self.videoDecoder) else: 0.0)

proc plm_get_pixel_aspect_ratio*(self: ptr plm_t): float64 =
  return (if plm_init_decoders(self) != 0 and self.videoDecoder !=
      nil: plm_video_get_pixel_aspect_ratio(self.videoDecoder) else: 0.0)

proc plm_get_num_audio_streams*(self: ptr plm_t): cint =
  return plm_demux_get_num_audio_streams(self.demux)

proc plm_get_samplerate*(self: ptr plm_t): cint =
  return (if plm_init_decoders(self) != 0 and self.audioDecoder != nil: plm_audio_get_samplerate(
      self.audioDecoder) else: 0)

proc plm_get_audio_lead_time*(self: ptr plm_t): float64 =
  return self.audioLeadTime

proc plm_set_audio_lead_time*(self: ptr plm_t, leadTime: float64) =
  self.audioLeadTime = leadTime

proc plm_get_time*(self: ptr plm_t): float64 =
  return self.time

proc plm_get_duration*(self: ptr plm_t): float64 =
  return plm_demux_get_duration(self.demux, PLM_DEMUX_PACKET_VIDEO_1)

proc plm_rewind*(self: ptr plm_t) =
  if self.videoDecoder != nil:
    plm_video_rewind(self.videoDecoder)
  if self.audioDecoder != nil:
    plm_audio_rewind(self.audioDecoder)
  plm_demux_rewind(self.demux)
  self.time = 0.0
  self.hasEnded = 0

proc plm_get_loop*(self: ptr plm_t): cint =
  return self.loop

proc plm_set_loop*(self: ptr plm_t, loop: cint) =
  self.loop = loop

proc plm_has_ended*(self: ptr plm_t): cint =
  return self.hasEnded

proc plm_set_video_decode_callback*(self: ptr plm_t, fp: plm_video_decode_callback,
    user: pointer) =
  self.videoDecodeCallback = fp
  self.videoDecodeCallbackUserData = user

proc plm_set_audio_decode_callback*(self: ptr plm_t, fp: plm_audio_decode_callback,
    user: pointer) =
  self.audioDecodeCallback = fp
  self.audioDecodeCallbackUserData = user

proc plm_decode*(self: ptr plm_t, seconds: float64) =
  if plm_init_decoders(self) == 0:
    return
  let decodeVideo: cint = (cint(self.videoDecodeCallback != nil and self.videoPacketType != 0))
  let decodeAudio: cint = (cint(self.audioDecodeCallback != nil and self.audioPacketType != 0))
  if decodeVideo == 0 and decodeAudio == 0:
    # Nothing to do here
    return
  var didDecode: cint = 0
  var decodeVideoFailed: cint = 0
  var decodeAudioFailed: cint = 0
  let videoTargetTime: float64 = self.time + seconds
  let audioTargetTime: float64 = self.time + seconds + self.audioLeadTime
  while true:
    didDecode = 0
    if decodeVideo != 0 and plm_video_get_time(self.videoDecoder) < videoTargetTime:
      let frame = plm_video_decode(self.videoDecoder)
      if frame != nil:
        self.videoDecodeCallback(self, frame, self.videoDecodeCallbackUserData)
        didDecode = 1
      else:
        decodeVideoFailed = 1
    if decodeAudio != 0 and plm_audio_get_time(self.audioDecoder) < audioTargetTime:
      let samples = plm_audio_decode(self.audioDecoder)
      if samples != nil:
        self.audioDecodeCallback(self, samples, self.audioDecodeCallbackUserData)
        didDecode = 1
      else:
        decodeAudioFailed = 1
    if didDecode == 0:
      break
  # Did all sources we wanted to decode fail and the demuxer is at the end?
  if (decodeVideo == 0 or decodeVideoFailed != 0) and (decodeAudio == 0 or decodeAudioFailed !=
      0) and plm_demux_has_ended(self.demux) != 0:
    plm_handle_end(self)
    return
  self.time += seconds

proc plm_decode_video*(self: ptr plm_t): ptr plm_frame_t =
  if plm_init_decoders(self) == 0:
    return nil
  if self.videoPacketType == 0:
    return nil
  let frame = plm_video_decode(self.videoDecoder)
  if frame != nil:
    self.time = frame.time
  elif plm_demux_has_ended(self.demux) != 0:
    plm_handle_end(self)
  return frame

proc plm_decode_audio*(self: ptr plm_t): ptr plm_samples_t =
  if plm_init_decoders(self) == 0:
    return nil
  if self.audioPacketType == 0:
    return nil
  let samples = plm_audio_decode(self.audioDecoder)
  if samples != nil:
    self.time = samples.time
  elif plm_demux_has_ended(self.demux) != 0:
    plm_handle_end(self)
  return samples

proc plm_handle_end(self: ptr plm_t) =
  if self.loop != 0:
    plm_rewind(self)
  else:
    self.hasEnded = 1

proc plm_read_video_packet(buffer: ptr plm_buffer_t, user: pointer) =
  let self = cast[ptr plm_t](user)
  plm_read_packets(self, self.videoPacketType)

proc plm_read_audio_packet(buffer: ptr plm_buffer_t, user: pointer) =
  let self = cast[ptr plm_t](user)
  plm_read_packets(self, self.audioPacketType)

proc plm_read_packets(self: ptr plm_t, requestedType: cint) =
  var packet: ptr plm_packet_t
  while true:
    packet = plm_demux_decode(self.demux)
    if packet == nil:
      break
    if packet.`type` == self.videoPacketType:
      discard plm_buffer_write(self.videoBuffer, packet.data, packet.length)
    elif packet.`type` == self.audioPacketType:
      discard plm_buffer_write(self.audioBuffer, packet.data, packet.length)
    if packet.`type` == requestedType:
      return
  if plm_demux_has_ended(self.demux) != 0:
    if self.videoBuffer != nil:
      plm_buffer_signal_end(self.videoBuffer)
    if self.audioBuffer != nil:
      plm_buffer_signal_end(self.audioBuffer)

proc plm_seek_frame*(self: ptr plm_t, time: float64, seekExact: cint): ptr plm_frame_t =
  var time = time
  if plm_init_decoders(self) == 0:
    return nil
  if self.videoPacketType == 0:
    return nil
  let `type`: cint = self.videoPacketType
  let startTime: float64 = plm_demux_get_start_time(self.demux, `type`)
  let duration: float64 = plm_demux_get_duration(self.demux, `type`)
  if time < 0.0:
    time = 0.0
  elif time > duration:
    time = duration
  let packet = plm_demux_seek(self.demux, time, `type`, 1)
  if packet == nil:
    return nil
  # Disable writing to the audio buffer while decoding video
  let previousAudioPacketType: cint = self.audioPacketType
  self.audioPacketType = 0
  # Clear video buffer and decode the found packet
  plm_video_rewind(self.videoDecoder)
  plm_video_set_time(self.videoDecoder, packet.pts - startTime)
  discard plm_buffer_write(self.videoBuffer, packet.data, packet.length)
  var frame: ptr plm_frame_t = plm_video_decode(self.videoDecoder)
  # If we want to seek to an exact frame, we have to decode all frames
  # on top of the intra frame we just jumped to.
  if seekExact != 0:
    while frame != nil and frame.time < time:
      frame = plm_video_decode(self.videoDecoder)
  # Enable writing to the audio buffer again?
  self.audioPacketType = previousAudioPacketType
  if frame != nil:
    self.time = frame.time
  self.hasEnded = 0
  return frame

proc plm_seek*(self: ptr plm_t, time: float64, seekExact: cint): cint =
  let frame = plm_seek_frame(self, time, seekExact)
  if frame == nil:
    return 0
  if self.videoDecodeCallback != nil:
    self.videoDecodeCallback(self, frame, self.videoDecodeCallbackUserData)
  # If audio is not enabled we are done here.
  if self.audioPacketType == 0:
    return 1
  let startTime: float64 = plm_demux_get_start_time(self.demux, self.videoPacketType)
  plm_audio_rewind(self.audioDecoder)
  var packet: ptr plm_packet_t = nil
  while true:
    packet = plm_demux_decode(self.demux)
    if packet == nil:
      break
    if packet.`type` == self.videoPacketType:
      discard plm_buffer_write(self.videoBuffer, packet.data, packet.length)
    elif packet.`type` == self.audioPacketType and packet.pts - startTime > self.time:
      plm_audio_set_time(self.audioDecoder, packet.pts - startTime)
      discard plm_buffer_write(self.audioBuffer, packet.data, packet.length)
      plm_decode(self, 0.0)
      break
  return 1
